module Z3
  class BitvecExpr < Expr
    def ~
      sort.new(LowLevel.mk_bvnot(self))
    end

    def !
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

    def xnor(other)
      BitvecExpr.Xnor(self, other)
    end

    def nand(other)
      BitvecExpr.Nand(self, other)
    end

    def nor(other)
      BitvecExpr.Nor(self, other)
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

    def /(other)
      raise "Use signed_div or unsigned_div"
    end

    def %(other)
      raise "Use signed_mod or signed_rem or unsigned_rem"
    end

    def rotate_left(num)
      sort.new(LowLevel.mk_rotate_left(num, self))
    end

    def rotate_right(num)
      sort.new(LowLevel.mk_rotate_right(num, self))
    end

    def extract(hi, lo)
      raise Z3::Exception, "Trying to extract bits out of range" unless sort.size > hi and hi >= lo and lo >= 0
      BitvecSort.new(hi - lo + 1).new(LowLevel.mk_extract(hi, lo, self))
    end

    def zero_ext(size)
      BitvecSort.new(sort.size + size).new(LowLevel.mk_zero_ext(size, self))
    end

    def sign_ext(size)
      BitvecSort.new(sort.size + size).new(LowLevel.mk_sign_ext(size, self))
    end

    def add_no_overflow?(other)
      raise Z3::Exception, "Use #signed_add_no_overflow? or #unsigned_add_no_overflow? for Bitvec, not #add_no_overflow?"
    end

    def add_no_overflow?(other)
      raise "Use signed_add_no_overflow? or unsigned_add_no_overflow?"
    end
    def signed_add_no_overflow?(other)
      BitvecExpr.SignedAddNoOverflow(self, other)
    end
    def unsigned_add_no_overflow?(other)
      BitvecExpr.UnsignedAddNoOverflow(self, other)
    end

    def add_no_underflow?(other)
      BitvecExpr.SignedAddNoUnderflow(self, other)
    end
    def signed_add_no_underflow?(other)
      BitvecExpr.SignedAddNoUnderflow(self, other)
    end
    def unsigned_add_no_underflow?(other)
      raise "Unsigned + cannot underflow"
    end

    def unsigned_neg_no_overflow?
      raise "There is no unsigned negation"
    end
    def signed_neg_no_overflow?
      BitvecExpr.SignedNegNoOverflow(self)
    end
    def neg_no_overflow?
      BitvecExpr.SignedNegNoOverflow(self)
    end

    def mul_no_overflow?(other)
      raise "Use signed_mul_no_overflow? or unsigned_mul_no_overflow?"
    end
    def signed_mul_no_overflow?(other)
      BitvecExpr.SignedMulNoOverflow(self, other)
    end
    def unsigned_mul_no_overflow?(other)
      BitvecExpr.UnsignedMulNoOverflow(self, other)
    end

    def mul_no_underflow?(other)
      BitvecExpr.SignedMulNoUnderflow(self, other)
    end
    def signed_mul_no_underflow?(other)
      BitvecExpr.SignedMulNoUnderflow(self, other)
    end
    def unsigned_mul_no_underflow?(other)
      raise "Unsigned + cannot underflow"
    end

    def div_no_overflow?(other)
      BitvecExpr.SignedDivNoOverflow(self, other)
    end
    def signed_div_no_overflow?(other)
      BitvecExpr.SignedDivNoOverflow(self, other)
    end
    def unsigned_div_no_overflow?(other)
      raise "Unsigned / cannot underflow"
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

      def UnsignedRShift(a, b)
        a, b = coerce_to_same_bv_sort(a, b)
        a.sort.new(LowLevel.mk_bvlshr(a, b))
      end

      # Signed/Unsigned work the same
      def LShift(a, b)
        a, b = coerce_to_same_bv_sort(a, b)
        a.sort.new(LowLevel.mk_bvshl(a, b))
      end

      def Xnor(*args)
        args = coerce_to_same_bv_sort(*args)
        args.inject do |a,b|
          a.sort.new(LowLevel.mk_bvxnor(a, b))
        end
      end

      def Nand(*args)
        args = coerce_to_same_bv_sort(*args)
        args.inject do |a,b|
          a.sort.new(LowLevel.mk_bvnand(a, b))
        end
      end

      def Nor(*args)
        args = coerce_to_same_bv_sort(*args)
        args.inject do |a,b|
          a.sort.new(LowLevel.mk_bvnor(a, b))
        end
      end

      def UnsignedGt(a, b)
        a, b = coerce_to_same_bv_sort(a, b)
        BoolSort.new.new(LowLevel.mk_bvugt(a, b))
      end

      def UnsignedGe(a, b)
        a, b = coerce_to_same_bv_sort(a, b)
        BoolSort.new.new(LowLevel.mk_bvuge(a, b))
      end

      def UnsignedLt(a, b)
        a, b = coerce_to_same_bv_sort(a, b)
        BoolSort.new.new(LowLevel.mk_bvult(a, b))
      end

      def UnsignedLe(a, b)
        a, b = coerce_to_same_bv_sort(a, b)
        BoolSort.new.new(LowLevel.mk_bvule(a, b))
      end

      def SignedGt(a, b)
        a, b = coerce_to_same_bv_sort(a, b)
        BoolSort.new.new(LowLevel.mk_bvsgt(a, b))
      end

      def SignedGe(a, b)
        a, b = coerce_to_same_bv_sort(a, b)
        BoolSort.new.new(LowLevel.mk_bvsge(a, b))
      end

      def SignedLt(a, b)
        a, b = coerce_to_same_bv_sort(a, b)
        BoolSort.new.new(LowLevel.mk_bvslt(a, b))
      end

      def SignedLe(a, b)
        a, b = coerce_to_same_bv_sort(a, b)
        BoolSort.new.new(LowLevel.mk_bvsle(a, b))
      end

      def SignedAddNoOverflow(a, b)
        a, b = coerce_to_same_bv_sort(a, b)
        BoolSort.new.new(LowLevel.mk_bvadd_no_overflow(a, b, true))
      end

      def UnsignedAddNoOverflow(a, b)
        a, b = coerce_to_same_bv_sort(a, b)
        BoolSort.new.new(LowLevel.mk_bvadd_no_overflow(a, b, false))
      end

      def SignedAddNoUnderflow(a, b)
        a, b = coerce_to_same_bv_sort(a, b)
        BoolSort.new.new(LowLevel.mk_bvadd_no_underflow(a, b))
      end

      def SignedNegNoOverflow(a)
        BoolSort.new.new(LowLevel.mk_bvneg_no_overflow(a))
      end

      def SignedMulNoOverflow(a, b)
        a, b = coerce_to_same_bv_sort(a, b)
        BoolSort.new.new(LowLevel.mk_bvmul_no_overflow(a, b, true))
      end

      def UnsignedMulNoOverflow(a, b)
        a, b = coerce_to_same_bv_sort(a, b)
        BoolSort.new.new(LowLevel.mk_bvmul_no_overflow(a, b, false))
      end

      def SignedMulNoUnderflow(a, b)
        a, b = coerce_to_same_bv_sort(a, b)
        BoolSort.new.new(LowLevel.mk_bvmul_no_underflow(a, b))
      end

      def SignedDivNoOverflow(a, b)
        a, b = coerce_to_same_bv_sort(a, b)
        BoolSort.new.new(LowLevel.mk_bvsdiv_no_overflow(a, b))
      end
    end
  end
end
