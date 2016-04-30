module Z3
  class BitvecExpr < Expr
    def ~
      sort.new(LowLevel.mk_bvnot(self))
    end

    def -@
      sort.new(LowLevel.mk_bvneg(self))
    end

    def &(other)
      Expr.And(self, other)
    end

    def |(other)
      Expr.Or(self, other)
    end

    def ^(other)
      Expr.Xor(self, other)
    end

    def +(other)
      Expr.Add(self, other)
    end

    def -(other)
      Expr.Sub(self, other)
    end

    def *(other)
      Expr.Mul(self, other)
    end

    def >>(other)
      raise Z3::Exception, "Use #signed_rshift or #unsigned_rshift for Bitvec, not >>"
    end

    def signed_rshift(other)
      BitvecExpr.SignedRShift(self, other)
    end

    def unsigned_rshift(other)
      BitvecExpr.UnsignedRShift(self, other)
    end

    def rshift(other)
      raise Z3::Exception, "Use #signed_rshift or #unsigned_rshift for Bitvec, not #rshift"
    end

    def <<(other)
      BitvecExpr.LShift(self, other)
    end

    def signed_lshift(other)
      BitvecExpr.LShift(self, other)
    end

    def unsigned_lshift(other)
      BitvecExpr.LShift(self, other)
    end

    def lshift(other)
      BitvecExpr.LShift(self, other)
    end

    def >(other)
      Expr.Gt(self, other)
    end

    def >=(other)
      Expr.Ge(self, other)
    end

    def <=(other)
      Expr.Le(self, other)
    end

    def <(other)
      Expr.Lt(self, other)
    end

    def signed_gt(other)
      BitvecExpr.SignedGt(self, other)
    end

    def signed_ge(other)
      BitvecExpr.SignedGe(self, other)
    end

    def signed_lt(other)
      BitvecExpr.SignedLt(self, other)
    end

    def signed_le(other)
      BitvecExpr.SignedLe(self, other)
    end

    def unsigned_gt(other)
      BitvecExpr.UnsignedGt(self, other)
    end

    def unsigned_ge(other)
      BitvecExpr.UnsignedGe(self, other)
    end

    def unsigned_lt(other)
      BitvecExpr.UnsignedLt(self, other)
    end

    def unsigned_le(other)
      BitvecExpr.UnsignedLe(self, other)
    end

    def coerce(other)
      other_sort = Expr.sort_for_const(other)
      max_sort = [sort, other_sort].max
      [max_sort.from_const(other), max_sort.from_value(self)]
    end

    public_class_method :new

    class << self
      def coerce_to_same_bv_sort(*args)
        args = coerce_to_same_sort(*args)
        raise Z3::Exception, "Bitvec value with same size expected" unless args[0].is_a?(BitvecExpr)
        args
      end

      def SignedRShift(a, b)
        a, b = coerce_to_same_bv_sort(a, b)
        a.sort.new(LowLevel.mk_bvashr(a, b))
      end

      def UnignedRShift(a, b)
        a, b = coerce_to_same_bv_sort(a, b)
        a.sort.new(LowLevel.mk_bvlshr(a, b))
      end

      # Signed/Unsigned act the same
      def LShift(a, b)
        a, b = coerce_to_same_bv_sort(a, b)
        a.sort.new(LowLevel.mk_bvshl(a, b))
      end

      def UnsignedGt(a, b)
        a, b = coerce_to_same_bv_sort(a, b)
        BoolSort.new.new(Z3::LowLevel.mk_bvugt(a, b))
      end

      def UnsignedGe(a, b)
        a, b = coerce_to_same_bv_sort(a, b)
        BoolSort.new.new(Z3::LowLevel.mk_bvuge(a, b))
      end

      def UnsignedLt(a, b)
        a, b = coerce_to_same_bv_sort(a, b)
        BoolSort.new.new(Z3::LowLevel.mk_bvult(a, b))
      end

      def UnsignedLe(a, b)
        a, b = coerce_to_same_bv_sort(a, b)
        BoolSort.new.new(Z3::LowLevel.mk_bvule(a, b))
      end

      def SignedGt(a, b)
        a, b = coerce_to_same_bv_sort(a, b)
        BoolSort.new.new(Z3::LowLevel.mk_bvsgt(a, b))
      end

      def SignedGe(a, b)
        a, b = coerce_to_same_bv_sort(a, b)
        BoolSort.new.new(Z3::LowLevel.mk_bvsge(a, b))
      end

      def SignedLt(a, b)
        a, b = coerce_to_same_bv_sort(a, b)
        BoolSort.new.new(Z3::LowLevel.mk_bvslt(a, b))
      end

      def SignedLe(a, b)
        a, b = coerce_to_same_bv_sort(a, b)
        BoolSort.new.new(Z3::LowLevel.mk_bvsle(a, b))
      end
    end
  end
end
