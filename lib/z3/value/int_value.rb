module Z3
  class IntValue < Value
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

    def -@
      sort.new(LowLevel.mk_unary_minus(self))
    end

    def coerce(other)
      [sort.from_const(other), self]
    end

    public_class_method :new
  end
end
