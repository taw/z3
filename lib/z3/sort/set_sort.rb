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

    # A Set is an `Array(X, Bool)`, and `ArraySort.new(X, BoolSort.new)` hands you one
    # of these instead of an ArraySort - so it has to answer to the Array vocabulary
    # too, or the redirect would quietly take methods away. Same reason StringSort has
    # `#element_sort`: the specialised sort still answers the general one's questions.
    def key_sort
      element_sort
    end

    def value_sort
      BoolSort.new
    end

    # `#Empty` and `#Full` are this with `false` and `true`
    def Const(value)
      new(LowLevel.mk_const_array(element_sort, BoolSort.new.cast(value)))
    end

    def to_s
      "Set(#{element_sort})"
    end

    def inspect
      "SetSort(#{element_sort})"
    end

    def Empty
      new(LowLevel.mk_empty_set(element_sort))
    end

    def Full
      new(LowLevel.mk_full_set(element_sort))
    end

    public_class_method :new
  end
end
