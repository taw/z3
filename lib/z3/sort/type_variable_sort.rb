module Z3
  class TypeVariableSort < Sort
    attr_reader :name
    def initialize(name)
      @name = name
      super LowLevel.mk_type_variable(LowLevel.mk_symbol(name))
    end

    def expr_class
      TypeVariableExpr
    end

    def inspect
      "TypeVariableSort(#{name})"
    end

    public_class_method :new
  end
end
