module Z3
  class SetSort < Sort
    attr_reader :element_sort
    def initialize(element_sort)
      @element_sort = element_sort
      super LowLevel.mk_set_sort(element_sort)
    end

    def expr_class
      SetExpr
    end

    def to_s
      "Set(#{element_sort})"
    end

    def inspect
      "SetSort(#{element_sort})"
    end

    public_class_method :new
  end
end
