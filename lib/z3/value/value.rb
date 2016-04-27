module Z3
  class Value < AST
    attr_reader :sort
    def initialize(_ast, sort)
      super(_ast)
      @sort = sort
      raise Z3::Exception, "Values must have AST kind numeral or app" unless [:numeral, :app].include?(ast_kind)
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
