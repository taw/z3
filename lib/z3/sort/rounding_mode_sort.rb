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

    def nearest_ties_away
      RoundingModeExpr.new(LowLevel.mk_fpa_round_nearest_ties_to_away, self)
    end

    def nearest_ties_even
      RoundingModeExpr.new(LowLevel.mk_fpa_round_nearest_ties_to_even, self)
    end

    def towards_zero
      RoundingModeExpr.new(LowLevel.mk_fpa_round_toward_zero, self)
    end

    def towards_negative
      RoundingModeExpr.new(LowLevel.mk_fpa_round_toward_negative, self)
    end

    def towards_positive
      RoundingModeExpr.new(LowLevel.mk_fpa_round_toward_positive, self)
    end

    public_class_method :new
  end
end
