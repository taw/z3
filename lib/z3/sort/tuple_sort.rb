module Z3
  # A tuple - a record of named fields, each with a sort of its own. It's a datatype
  # with a single constructor, and the one datatype Z3 builds without the whole
  # `Z3_constructor` apparatus, so it's the way to key an array by a pair, or to have
  # an uninterpreted function return more than one value.
  #
  # Fields are read as methods - `p.x` - or with `#[]` for a name a method can't have.
  class TupleSort < Sort
    attr_reader :name, :fields, :constructor, :accessors

    # Both ways in already have the sort in hand - ::new declares it, ::from_pointer
    # gets it back from Z3 - so this only ever wraps one
    def initialize(_sort, name, fields, _constructor, _accessors)
      @name = name
      @fields = fields
      @constructor = FuncDecl.new(_constructor)
      @accessors = fields.keys.zip(_accessors.map { |_accessor| FuncDecl.new(_accessor) }).to_h
      super(_sort)
    end

    # One expr class per tuple sort, since each has its own field readers. Memoized,
    # and sorts are memoized too, so there's exactly one of these per tuple.
    def expr_class
      @expr_class ||= TupleExpr.class_for(self)
    end

    # The accessor decl behind a field. `point.accessor(:x)[p]` is what `p.x` builds.
    def accessor(field)
      field = field.to_sym if field.is_a?(String)
      accessors.fetch(field) { raise Z3::Exception, "#{self} has no field #{field.inspect}, only #{fields.keys.map(&:inspect).join(", ")}" }
    end

    # Builds a value, one argument per field, in declaration order. Arguments are cast
    # to the field sorts, so `point.mk(3, 4)` takes Ruby Integers.
    def mk(*args)
      unless args.size == fields.size
        raise Z3::Exception, "#{self} has #{fields.size} fields, got #{args.size} argument#{"s" unless args.size == 1}"
      end
      # Cast here rather than leaving it to FuncDecl#[], so that a value of the wrong
      # sort says which field it was meant for - "Can't convert true into Int" on its
      # own says very little about a tuple with several Int fields
      values = fields.to_a.zip(args).map do |(field, field_sort), arg|
        begin
          field_sort.cast(arg)
        rescue Z3::Exception => e
          raise Z3::Exception, "#{self} field #{field.inspect}: #{e.message}"
        end
      end
      constructor[*values]
    end

    # An Array is the fields in order, a Hash names them - `[3, 4]` and
    # `{x: 3, y: 4}` build the same value
    def from_const(v)
      case v
      when Array
        mk(*v)
      when Hash
        from_hash(v)
      else
        raise cant_convert(v)
      end
    end

    def inspect
      "TupleSort(#{name}, #{fields.map { |field, sort| "#{field}: #{sort}" }.join(", ")})"
    end

    private

    # Every field named once, and nothing else - a Hash is the spelling where a typo
    # in a field name is possible at all, so an unknown key is an error rather than
    # something to ignore
    def from_hash(hash)
      hash = hash.map { |field, value| [field.is_a?(String) ? field.to_sym : field, value] }.to_h
      unknown = hash.keys - fields.keys
      raise Z3::Exception, "#{self} has no field #{unknown.map(&:inspect).join(", ")}" unless unknown.empty?
      mk(*fields.keys.map { |field| hash.fetch(field) { raise Z3::Exception, "#{self} needs a value for field #{field.inspect}" } })
    end

    class << self
      # Tuples are memoized by name for the same reason enums are, and more urgently.
      # Z3 hands back the sort it already has for the name, but rebuilds its
      # constructor and accessors from the fields passed this time - so a second
      # declaration with different fields doesn't fail, it silently replaces what the
      # sort says its fields are, and every term built against the first declaration
      # is left behind. Asking twice for the same tuple gives back the same sort,
      # asking for the same name with different fields raises.
      def new(name, fields)
        name = normalize_name(name)
        fields = normalize_fields(fields)
        already_declared = registry[name]
        if already_declared
          # Compared as lists, since a tuple's fields are ordered and Hash#== isn't -
          # `mk(3, 4)` means something different to whoever wrote `y:` first
          unless already_declared.fields.to_a == fields.to_a
            raise Z3::Exception, "Tuple sort #{name} is already declared, with fields #{already_declared.fields.map { |field, sort| "#{field}: #{sort}" }.join(", ")}"
          end
          return already_declared
        end
        # Enums and tuples share the datatype namespace, and this is the direction Z3
        # doesn't refuse: declaring a tuple over an enum's name takes the name over,
        # leaving the enum's own values unbuildable
        if EnumSort.declared?(name)
          raise Z3::Exception, "Tuple sort #{name} can't be declared, #{name} is already an enum sort"
        end
        _sort, _constructor, _accessors = LowLevel.mk_tuple_sort(
          LowLevel.mk_symbol(name),
          fields.keys.map { |field| LowLevel.mk_symbol(field.to_s) },
          fields.values,
        )
        registry[name] = build(_sort, name, fields, _constructor, _accessors)
      end

      # Takes a raw sort pointer, as Sort.from_pointer needs it before there's any
      # Sort object. Rebuilds rather than redeclares, so it works for a tuple Z3 handed
      # us - out of a model, or parsed from a file - and not just for ones we declared.
      def from_pointer(_sort)
        name = Sort.name_from_pointer(_sort)
        registry[name] ||= begin
          _constructor = VeryLowLevel.Z3_get_datatype_sort_constructor(LowLevel._ctx_pointer, _sort, 0)
          constructor = FuncDecl.new(_constructor)
          _accessors = constructor.arity.times.map do |i|
            VeryLowLevel.Z3_get_datatype_sort_constructor_accessor(LowLevel._ctx_pointer, _sort, 0, i)
          end
          fields = _accessors.each_with_index.map { |_accessor, i| [FuncDecl.new(_accessor).name.to_sym, constructor.domain(i)] }.to_h
          build(_sort, name, fields, _constructor, _accessors)
        end
      end

      # Whether this process declared a tuple of that name - EnumSort asks, so that
      # the two of them don't take each other's names
      def declared?(name)
        registry.key?(normalize_name(name))
      end

      private

      # ::new is the declaring path, so wrapping a sort which already exists needs a
      # way in of its own
      def build(_sort, name, fields, _constructor, _accessors)
        sort = allocate
        sort.send(:initialize, _sort, name, fields, _constructor, _accessors)
        sort
      end

      # Z3 symbols are either strings or integers, and Sort.name_from_pointer hands
      # back whichever it was, so both paths have to agree on which is which or one
      # sort would end up under two registry keys
      def normalize_name(name)
        name.is_a?(Integer) ? name : name.to_s
      end

      def normalize_fields(fields)
        raise Z3::Exception, "Tuple sort needs a Hash of fields, got #{AST.describe(fields)}" unless fields.is_a?(Hash)
        normalized = fields.map do |field, sort|
          unless field.is_a?(Symbol) or field.is_a?(String)
            raise Z3::Exception, "Tuple field names must be Symbols, got #{AST.describe(field)}"
          end
          raise Z3::Exception, "Tuple field #{field} needs a Sort, got #{AST.describe(sort)}" unless sort.is_a?(Sort)
          [field.to_sym, sort]
        end
        # A tuple with no fields is the same Z3 sort as an enum with one value - one
        # nullary constructor - so there'd be no telling them apart coming back out
        # of a model, and nothing to gain by having both
        raise Z3::Exception, "Tuple sort needs at least one field" if normalized.empty?
        repeated = normalized.map(&:first).tally.select { |_, count| count > 1 }.keys
        # `{x: Int, "x" => Real}` is two Hash keys and one field
        raise Z3::Exception, "Tuple field names must be distinct, #{repeated.map(&:inspect).join(", ")} repeated" unless repeated.empty?
        normalized.to_h
      end

      def registry
        @registry ||= {}
      end
    end
  end
end
