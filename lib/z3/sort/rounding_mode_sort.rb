module Z3
  class RoundingModeSort < Sort
    def initialize
      super LowLevel.mk_fpa_rounding_mode_sort
    end

    def expr_class
      RoundingModeExpr
    end

    def to_s
      "RoundingMode"
    end

    def inspect
      "RoundingModeSort"
    end

    public_class_method :new
  end
end
