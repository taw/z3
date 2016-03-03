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

    def coerce(other)
      [sort.from_const(other), self]
    end
  end
end
