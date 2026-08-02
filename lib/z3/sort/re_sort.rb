module Z3
  class ReSort < Sort
    attr_reader :seq_sort
    def initialize(seq_sort)
      @seq_sort = seq_sort
      super LowLevel.mk_re_sort(seq_sort)
    end

    def expr_class
      ReExpr
    end

    def to_s
      "Re(#{seq_sort})"
    end

    def inspect
      "ReSort(#{seq_sort})"
    end

    public_class_method :new
  end
end
