module Z3
  class Value
    attr_reader :_ast, :sort
    def initialize(_ast, sort)
      @_ast = _ast
      @sort = sort
    end

    def to_s
      Z3::LowLevel.ast_to_string(self)
    end

    def inspect
      "Value<#{to_s} :: #{sort.to_s}>"
    end

    def ==(other)
      ::Z3.Eq(self, other)
    end

    def !=(other)
      ::Z3.Distinct(self, other)
    end

    private_class_method :new

    class << self
      def sort_for_const(a)
        case a
        when TrueClass, FalseClass
          BoolSort.new
        when Integer
          IntSort.new
        when Float
          RealSort.new
        else
          raise Z3::Exception, "No idea how to autoconvert `#{a.class}': `#{a.inspect}'"
        end
      end

      def new_from_pointer(_ast)
        _sort = Z3::VeryLowLevel.Z3_get_sort(Z3::LowLevel._ctx_pointer, _ast)
        Sort.from_pointer(_sort).new(_ast)
      end
    end
  end
end
