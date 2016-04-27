module Z3
  class BitvecExpr < Expr
    def ~
      sort.new(LowLevel.mk_bvnot(self))
    end

    def -@
      sort.new(LowLevel.mk_bvneg(self))
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

    def +(other)
      ::Z3.Add(self, other)
    end

    def -(other)
      ::Z3.Sub(self, other)
    end

    def *(other)
      ::Z3.Mul(self, other)
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

    def coerce(other)
      other_sort = Value.sort_for_const(other)
      max_sort = [sort, other_sort].max
      [max_sort.from_const(other), max_sort.from_value(self)]
    end

    public_class_method :new
  end
end
