module Z3
  class BoolValue < Value
    def ~
      sort.new(LowLevel.mk_not(self))
    end

    def &(other)
      Z3.And(self, other)
    end

    def |(other)
      Z3.Or(self, other)
    end

    def ^(other)
      Z3.Xor(self, other)
    end

    def iff(other)
      Z3.Iff(self, other)
    end

    def implies(other)
      Z3.Implies(self, other)
    end

    def ite(a, b)
      Z3.IfThenElse(self, a, b)
    end

    public_class_method :new
  end
end
