module Z3
  class BitvecValue < Value
    def ~
      ::Z3.Not(self)
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

    def >>(other)
      Z3.RShift(self, other)
    end

    def <<(other)
      Z3.LShift(self, other)
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

    public_class_method :new
  end
end
