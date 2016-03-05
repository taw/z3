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
      def new_from_pointer(_ast)
        _txt = Z3::VeryLowLevel.Z3_ast_to_string(Z3::LowLevel._ctx_pointer, _ast)
        # raise "No idea how to convert this value"
        # if == Z3::LowLevel.mk_bool_sort
      end
    end
  end
end
