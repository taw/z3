module Z3
  class UninterpretedSort < Sort
    attr_reader :name
    def initialize(name)
      @name = name
      super LowLevel.mk_uninterpreted_sort(LowLevel.mk_symbol(name))
    end

    def expr_class
      UninterpretedExpr
    end

    def inspect
      "UninterpretedSort(#{name})"
    end

    public_class_method :new
  end
end
