module Z3
  # An algebraic datatype - several named constructors, each taking any number of
  # named fields, and any of those fields may be the sort being declared:
  #
  #   Option = Z3::DatatypeSort.new("Option", none: [], some: {value: int})
  #   List   = Z3::DatatypeSort.new("List", nil: [], cons: {head: int, tail: :self})
  #
  # `:self` is the one field sort which can't be a Sort object, since the sort doesn't
  # exist yet while it's being declared. A field of some *other* datatype is an
  # ordinary Sort - only a group of mutually recursive datatypes needs more than this,
  # and that's `Z3_mk_datatypes`, which the gem doesn't have.
  #
  # Two shapes of datatype belong to other classes, and asking for them here gives
  # back that class instead - the way `ArraySort.new(x, BoolSort.new)` gives a
  # `SetSort`, and for the same reason: Z3 makes the same sort either way, so
  # `Sort.from_pointer` couldn't tell them apart afterwards. Every constructor nullary
  # is an `EnumSort`, and a single constructor with fields is a `TupleSort`. The
  # tuple's constructor is named after the sort, so `DatatypeSort.new("Box", wrap: {v: int})`
  # comes back with its constructor called `Box` rather than `wrap`.
  class DatatypeSort < Sort
    attr_reader :name, :constructors

    # Both ways in already have the sort in hand - ::new declares it, ::from_pointer
    # gets it back from Z3 - so this only ever wraps one.
    #
    # `constructors` maps each constructor name to its fields, and a field's sort is
    # either a Sort or `:self`, kept unresolved so that a recursive datatype doesn't
    # have to contain itself before it exists.
    def initialize(_sort, name, constructors)
      @name = name
      @constructors = constructors
      super(_sort)
    end

    # One expr class per datatype sort, since each has its own recognizers and field
    # readers. Memoized, and sorts are memoized too, so there's exactly one per sort.
    def expr_class
      @expr_class ||= DatatypeExpr.class_for(self)
    end

    def constructor_names
      constructors.keys
    end

    # A constructor's fields, with `:self` resolved to this sort. That resolution is
    # why it's a method and not just `constructors[name]`.
    def fields(constructor_name)
      constructor_fields(constructor_name).transform_values { |sort| sort == :self ? self : sort }
    end

    # Every field of every constructor. Field names are distinct across the whole
    # datatype, which is what lets #accessor and DatatypeExpr#[] take a bare name.
    def field_names
      constructors.values.flat_map(&:keys)
    end

    # The constructor declaration - `List.constructor(:cons)[10, tail]` is what
    # `List.mk(:cons, 10, tail)` builds
    def constructor(constructor_name)
      decls_for(constructor_name)[:constructor]
    end

    # The recognizer declaration - `List.recognizer(:nil)[l]` is `l.is_nil`.
    #
    # Looked up by index rather than by name: Z3 calls every recognizer of every
    # datatype `is`, so the names don't distinguish them.
    def recognizer(constructor_name)
      decls_for(constructor_name)[:recognizer]
    end

    # The accessor declaration behind a field. `List.accessor(:head)[l]` is `l.head`.
    def accessor(field)
      field = field.to_sym if field.is_a?(String)
      constructors.each_key do |constructor_name|
        i = constructor_fields(constructor_name).keys.index(field)
        return decls_for(constructor_name)[:accessors][i] if i
      end
      raise Z3::Exception, "#{self} has no field #{field.inspect}, only #{field_names.map(&:inspect).join(", ")}"
    end

    # Builds a value, one argument per field of that constructor, in declaration
    # order. Arguments are cast to the field sorts, so `List.mk(:cons, 10, List[:nil])`
    # takes a Ruby Integer.
    def mk(constructor_name, *args)
      field_sorts = fields(constructor_name)
      unless args.size == field_sorts.size
        raise Z3::Exception, "#{self} constructor #{constructor_name.inspect} takes #{field_sorts.size} argument#{"s" unless field_sorts.size == 1}, got #{args.size}"
      end
      # Cast here rather than leaving it to FuncDecl#[], so that a value of the wrong
      # sort says which field it was meant for
      values = field_sorts.to_a.zip(args).map do |(field, field_sort), arg|
        begin
          field_sort.cast(arg)
        rescue Z3::Exception => e
          raise Z3::Exception, "#{self} field #{field.inspect}: #{e.message}"
        end
      end
      constructor(constructor_name)[*values]
    end

    # A Symbol is a constructor which takes no fields, the way an enum value is; a
    # one-key Hash is any constructor, with its fields named or in order:
    #
    #   List[:nil]
    #   List[cons: {head: 10, tail: :nil}]
    #   List[cons: [10, :nil]]
    def from_const(v)
      case v
      when Symbol, String
        constructor_name = v.to_sym
        raise cant_convert(v) unless constructors.key?(constructor_name)
        unless constructor_fields(constructor_name).empty?
          raise Z3::Exception, "#{self} constructor #{constructor_name.inspect} takes fields, so it needs #{{constructor_name => constructor_fields(constructor_name).keys.map { |f| [f, "..."] }.to_h}.inspect} rather than a bare #{v.inspect}"
        end
        mk(constructor_name)
      when Hash
        raise Z3::Exception, "#{self} value needs exactly one constructor, got #{v.keys.map(&:inspect).join(", ")}" unless v.size == 1
        constructor_name, args = v.first
        constructor_name = constructor_name.to_sym if constructor_name.is_a?(String)
        raise cant_convert(v) unless constructors.key?(constructor_name)
        case args
        when Array
          mk(constructor_name, *args)
        when Hash
          mk(constructor_name, *field_args(constructor_name, args))
        else
          raise cant_convert(v)
        end
      else
        raise cant_convert(v)
      end
    end

    def [](v)
      from_const(v)
    end

    def inspect
      "DatatypeSort(#{name}, #{constructors.map { |c, fs| "#{c}: {#{fs.map { |f, s| "#{f}: #{s == :self ? ":self" : s}" }.join(", ")}}" }.join(", ")})"
    end

    private

    def constructor_fields(constructor_name)
      constructor_name = constructor_name.to_sym if constructor_name.is_a?(String)
      constructors.fetch(constructor_name) do
        raise Z3::Exception, "#{self} has no constructor #{constructor_name.inspect}, only #{constructor_names.map(&:inspect).join(", ")}"
      end
    end

    # Every field named once, and nothing else - a Hash is the spelling where a typo
    # in a field name is possible at all, so an unknown key is an error rather than
    # something to ignore
    def field_args(constructor_name, hash)
      hash = hash.map { |field, value| [field.is_a?(String) ? field.to_sym : field, value] }.to_h
      declared = constructor_fields(constructor_name).keys
      unknown = hash.keys - declared
      raise Z3::Exception, "#{self} constructor #{constructor_name.inspect} has no field #{unknown.map(&:inspect).join(", ")}" unless unknown.empty?
      declared.map { |field| hash.fetch(field) { raise Z3::Exception, "#{self} constructor #{constructor_name.inspect} needs a value for field #{field.inspect}" } }
    end

    # Z3 hands the constructor, recognizer and accessor declarations back off the sort,
    # so they're read once, lazily, rather than kept from whichever way in built it -
    # which is what lets ::from_pointer work at all.
    def decls_for(constructor_name)
      constructor_name = constructor_name.to_sym if constructor_name.is_a?(String)
      constructor_fields(constructor_name)
      decls[constructor_name]
    end

    def decls
      @decls ||= constructors.each_with_index.map do |(constructor_name, fields), i|
        [
          constructor_name,
          {
            constructor: FuncDecl.new(VeryLowLevel.Z3_get_datatype_sort_constructor(LowLevel._ctx_pointer, _ast, i)),
            recognizer: FuncDecl.new(VeryLowLevel.Z3_get_datatype_sort_recognizer(LowLevel._ctx_pointer, _ast, i)),
            accessors: fields.size.times.map do |j|
              FuncDecl.new(VeryLowLevel.Z3_get_datatype_sort_constructor_accessor(LowLevel._ctx_pointer, _ast, i, j))
            end,
          },
        ]
      end.to_h
    end

    class << self
      # Datatypes are memoized by name for the same reason tuples are. Z3 hands back
      # the sort it already has for the name and then attaches a fresh set of
      # constructors to it, so a second declaration with different constructors doesn't
      # fail - it leaves the sort with two incompatible sets of declarations, and terms
      # built against either one still typecheck. Asking twice for the same datatype
      # gives back the same sort, asking for the same name with different constructors
      # raises.
      def new(name, constructors)
        name = normalize_name(name)
        constructors = normalize_constructors(constructors)

        # The two shapes which are other classes' sorts. Done before the registry, so
        # that DatatypeSort.new and Sort.from_pointer agree about them either way.
        if constructors.each_value.all?(&:empty?)
          return EnumSort.new(name, constructors.keys)
        end
        if constructors.size == 1
          fields = constructors.values.first
          return TupleSort.new(name, fields) unless fields.each_value.include?(:self)
        end

        already_declared = registry[name]
        if already_declared
          unless already_declared.constructors == constructors
            raise Z3::Exception, "Datatype sort #{name} is already declared, as #{already_declared.inspect}"
          end
          return already_declared
        end
        if EnumSort.declared?(name)
          raise Z3::Exception, "Datatype sort #{name} can't be declared, #{name} is already an enum sort"
        end
        if TupleSort.declared?(name)
          raise Z3::Exception, "Datatype sort #{name} can't be declared, #{name} is already a tuple sort"
        end

        # Z3_constructor objects are heap objects with a lifecycle of their own, and
        # they exist only to be handed to mk_datatype - everything they carry is
        # readable off the sort afterwards, so they're freed straight away.
        _constructors = constructors.map do |constructor_name, fields|
          LowLevel.mk_constructor(
            LowLevel.mk_symbol(constructor_name.to_s),
            LowLevel.mk_symbol("is_#{constructor_name}"),
            fields.keys.map { |field| LowLevel.mk_symbol(field.to_s) },
            fields.values.map { |sort| sort == :self ? nil : sort },
          )
        end
        begin
          _sort = LowLevel.mk_datatype(LowLevel.mk_symbol(name), _constructors)
        ensure
          _constructors.each { |_constructor| LowLevel.del_constructor(_constructor) }
        end
        registry[name] = build(_sort, name, constructors)
      end

      # Takes a raw sort pointer, as Sort.from_pointer needs it before there's any
      # Sort object. Rebuilds rather than redeclares, so it works for a datatype Z3
      # handed us - out of a model, or parsed from a file - and not just for ones we
      # declared.
      def from_pointer(_sort)
        name = Sort.name_from_pointer(_sort)
        registry[name] ||= begin
          num = VeryLowLevel.Z3_get_datatype_sort_num_constructors(LowLevel._ctx_pointer, _sort)
          constructors = num.times.map do |i|
            constructor = FuncDecl.new(VeryLowLevel.Z3_get_datatype_sort_constructor(LowLevel._ctx_pointer, _sort, i))
            fields = constructor.arity.times.map do |j|
              accessor = FuncDecl.new(VeryLowLevel.Z3_get_datatype_sort_constructor_accessor(LowLevel._ctx_pointer, _sort, i, j))
              _field_sort = LowLevel.get_domain(constructor, j)
              # A recursive field can't be wrapped as a Sort here - that would come
              # straight back to this method for a sort which isn't in the registry
              # yet - so it stays `:self`, the same way a declaration writes it
              [accessor.name.to_sym, _field_sort.address == _sort.address ? :self : Sort.from_pointer(_field_sort)]
            end.to_h
            [constructor.name.to_sym, fields]
          end.to_h
          build(_sort, name, constructors)
        end
      end

      # Whether this process declared a datatype of that name - EnumSort and TupleSort
      # ask, so that the three of them don't take each other's names
      def declared?(name)
        registry.key?(normalize_name(name))
      end

      private

      # ::new is the declaring path, so wrapping a sort which already exists needs a
      # way in of its own
      def build(_sort, name, constructors)
        sort = allocate
        sort.send(:initialize, _sort, name, constructors)
        sort
      end

      # Z3 symbols are either strings or integers, and Sort.name_from_pointer hands
      # back whichever it was, so both paths have to agree on which is which or one
      # sort would end up under two registry keys
      def normalize_name(name)
        name.is_a?(Integer) ? name : name.to_s
      end

      # `none: []` and `none: {}` are the same declaration - a constructor with no
      # fields - and both read naturally, so both are taken
      def normalize_constructors(constructors)
        raise Z3::Exception, "Datatype sort needs a Hash of constructors, got #{AST.describe(constructors)}" unless constructors.is_a?(Hash)
        raise Z3::Exception, "Datatype sort needs at least one constructor" if constructors.empty?
        normalized = constructors.map do |constructor_name, fields|
          unless constructor_name.is_a?(Symbol) or constructor_name.is_a?(String)
            raise Z3::Exception, "Datatype constructor names must be Symbols, got #{AST.describe(constructor_name)}"
          end
          [constructor_name.to_sym, normalize_fields(constructor_name, fields)]
        end
        repeated_constructors = normalized.map(&:first).tally.select { |_, count| count > 1 }.keys
        unless repeated_constructors.empty?
          raise Z3::Exception, "Datatype constructor names must be distinct, #{repeated_constructors.map(&:inspect).join(", ")} repeated"
        end
        # Across the whole datatype, not just within one constructor - Z3 refuses
        # repeated accessor names itself, and a bare field name has to mean one thing
        # for DatatypeExpr#[] and the field readers to work
        repeated_fields = normalized.flat_map { |_, fields| fields.keys }.tally.select { |_, count| count > 1 }.keys
        unless repeated_fields.empty?
          raise Z3::Exception, "Datatype field names must be distinct, #{repeated_fields.map(&:inspect).join(", ")} repeated"
        end
        normalized.to_h
      end

      def normalize_fields(constructor_name, fields)
        fields = {} if fields.is_a?(Array) and fields.empty?
        unless fields.is_a?(Hash)
          raise Z3::Exception, "Datatype constructor #{constructor_name} needs a Hash of fields, got #{AST.describe(fields)}"
        end
        fields.map do |field, sort|
          unless field.is_a?(Symbol) or field.is_a?(String)
            raise Z3::Exception, "Datatype field names must be Symbols, got #{AST.describe(field)}"
          end
          unless sort.is_a?(Sort) or sort == :self
            raise Z3::Exception, "Datatype field #{field} needs a Sort or :self, got #{AST.describe(sort)}"
          end
          [field.to_sym, sort]
        end.to_h
      end

      def registry
        @registry ||= {}
      end
    end
  end
end
