module Z3
  class SeqSort < Sort
    attr_reader :element_sort
    def initialize(element_sort)
      @element_sort = element_sort
      super LowLevel.mk_seq_sort(element_sort)
    end

    def expr_class
      Expr
    end

    def to_s
      "Seq(#{element_sort})"
    end

    def inspect
      "SeqSort(#{element_sort})"
    end

    public_class_method :new
  end
end
