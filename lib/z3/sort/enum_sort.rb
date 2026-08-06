module Z3
  # An enumeration - a sort whose values are a fixed, finite list of names, and
  # nothing else. Values are Symbols, and every enum has its own: `Color[:red]` and
  # `Squirrel[:red]` are different values of different sorts, and Z3 refuses to
  # compare them.
  class EnumSort < Sort
    attr_reader :name, :values

    # Both ways in already have the sort in hand - ::new declares it, ::from_pointer
    # gets it back from Z3 - so this only ever wraps one
    def initialize(_sort, name, values)
      @name = name
      @values = values
      super(_sort)
    end

    def expr_class
      EnumExpr
    end

    # The nullary constructor behind each value, in declaration order. Memoized
    # because #[] and EnumExpr#value both go through it, and sorts are memoized too,
    # so there's exactly one of these per enum.
    def constructors
      @constructors ||= values.size.times.map { |i| FuncDecl.new(LowLevel.get_datatype_sort_constructor(self, i)) }
    end

    def [](value)
      i = values.index(value.to_sym) if value.is_a?(Symbol) or value.is_a?(String)
      raise cant_convert(value) unless i
      new(LowLevel.mk_app(constructors[i], []))
    end

    def from_const(value)
      self[value]
    end

    def inspect
      "EnumSort(#{name}, #{values.inspect})"
    end

    class << self
      # Every other named sort can be rebuilt just by calling its maker again, since
      # Z3 hash-conses them. Enumerations are the one exception - declaring the same
      # name twice is an error rather than the sort you already had - so they're
      # memoized by name here, and asking for the same one twice gives it back.
      def new(name, values)
        name = normalize_name(name)
        values = normalize_values(values)
        already_declared = registry[name]
        if already_declared
          unless already_declared.values == values
            raise Z3::Exception, "Enum sort #{name} is already declared, with values #{already_declared.values.inspect}"
          end
          return already_declared
        end
        # Enums and tuples share the datatype namespace, so the name has to be free of
        # both. Z3 refuses this one itself, with "enumeration sort name is already
        # declared" and no mention of what took it - see TupleSort.new for the other
        # direction, which Z3 doesn't refuse at all.
        if TupleSort.declared?(name)
          raise Z3::Exception, "Enum sort #{name} can't be declared, #{name} is already a tuple sort"
        end
        _sort = LowLevel.mk_enumeration_sort(
          LowLevel.mk_symbol(name),
          values.map { |value| LowLevel.mk_symbol(value) },
        )
        registry[name] = build(_sort, name, values)
      end

      # Takes a raw sort pointer, as Sort.from_pointer needs it before there's any
      # Sort object. Rebuilds rather than redeclares, so it works for a sort Z3
      # handed us - out of a model, or parsed from a file - and not just for ones
      # this process declared.
      def from_pointer(_sort)
        name = Sort.name_from_pointer(_sort)
        registry[name] ||= build(_sort, name, values_from_pointer(_sort, name))
      end

      # Whether this process declared an enum of that name - TupleSort asks, so that
      # the two of them don't take each other's names
      def declared?(name)
        registry.key?(normalize_name(name))
      end

      private

      # Not every datatype sort is an enumeration - a constructor which takes
      # arguments is a record or a tree, and there's nothing here to represent it
      def values_from_pointer(_sort, name)
        num = VeryLowLevel.Z3_get_datatype_sort_num_constructors(LowLevel._ctx_pointer, _sort)
        num.times.map do |i|
          constructor = FuncDecl.new(VeryLowLevel.Z3_get_datatype_sort_constructor(LowLevel._ctx_pointer, _sort, i))
          unless constructor.arity == 0
            raise Z3::Exception, "Datatype sort #{name} is not an enumeration, its constructor #{constructor.name} takes arguments"
          end
          constructor.name.to_sym
        end
      end

      # ::new is the declaring path, so wrapping a sort which already exists needs a
      # way in of its own
      def build(_sort, name, values)
        sort = allocate
        sort.send(:initialize, _sort, name, values)
        sort
      end

      # Z3 symbols are either strings or integers, and Sort.name_from_pointer hands
      # back whichever it was, so both paths have to agree on which is which or one
      # sort would end up under two registry keys
      def normalize_name(name)
        name.is_a?(Integer) ? name : name.to_s
      end

      def normalize_values(values)
        raise Z3::Exception, "Enum sort needs a list of values" unless values.is_a?(Enumerable)
        values = values.map do |value|
          raise Z3::Exception, "Enum values must be Symbols, got #{AST.describe(value)}" unless value.is_a?(Symbol) or value.is_a?(String)
          value.to_sym
        end
        # Z3 accepts both of these, and the results are worse than an error: an enum
        # with no values isn't well-founded, and repeated names make two distinct
        # values which print identically and which #value can't tell apart
        raise Z3::Exception, "Enum sort needs at least one value" if values.empty?
        repeated = values.tally.select { |_, count| count > 1 }.keys
        raise Z3::Exception, "Enum values must be distinct, #{repeated.map(&:inspect).join(", ")} repeated" unless repeated.empty?
        values
      end

      def registry
        @registry ||= {}
      end
    end
  end
end
