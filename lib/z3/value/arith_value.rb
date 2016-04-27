module Z3
  # IntValue / RealValue
  module ArithValue
    def +(other)
      ::Z3.Add(self, other)
    end

    def -(other)
      ::Z3.Sub(self, other)
    end

    def *(other)
      ::Z3.Mul(self, other)
    end

    def /(other)
      ::Z3.Div(self, other)
    end

    def mod(other)
      ::Z3.Mod(self, other)
    end

    def rem(other)
      ::Z3.Rem(self, other)
    end

    def **(other)
      ::Z3.Power(self, other)
    end

    def >(other)
      ::Z3.Gt(self, other)
    end

    def >=(other)
      ::Z3.Ge(self, other)
    end

    def <=(other)
      ::Z3.Le(self, other)
    end

    def <(other)
      ::Z3.Lt(self, other)
    end

    def -@
      sort.new(LowLevel.mk_unary_minus(self))
    end

    # Recast so 1 + x:Float
    # is:  (+ 1.0 x)
    # not: (+ (to_real 1) x)
    def coerce(other)
      other_sort = Value.sort_for_const(other)
      max_sort = [sort, other_sort].max
      [max_sort.from_const(other), max_sort.from_value(self)]
    end
  end
end
