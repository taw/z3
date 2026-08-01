module Z3
  class CharSort < Sort
    def initialize
      super LowLevel.mk_char_sort
    end

    def expr_class
      Expr
    end

    def to_s
      "Char"
    end

    public_class_method :new
  end
end
