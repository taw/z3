module Z3
  # Z3 internally represents String as Seq(Char), so StringSort == SeqSort.new(CharSort.new)
  class StringSort < Sort
    def initialize
      super LowLevel.mk_string_sort
    end

    def expr_class
      Expr
    end

    public_class_method :new
  end
end
