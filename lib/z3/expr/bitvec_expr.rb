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
      raise Z3::Exception, "Use signed_div or unsigned_div"
    end

    def signed_div(other)
      BitvecExpr.SignedDiv(self, other)
    end

    def unsigned_div(other)
      BitvecExpr.UnsignedDiv(self, other)
    end

    def %(other)
      raise Z3::Exception, "Use signed_mod or signed_rem or unsigned_rem"
    end

    def signed_mod(other)
      BitvecExpr.SignedMod(self, other)
    end

    def signed_rem(other)
      BitvecExpr.SignedRem(self, other)
    end

    def unsigned_rem(other)
      BitvecExpr.UnsignedRem(self, other)
    end

    # An Integer rotates by a fixed amount, a Bitvec of the same size by whatever it
    # turns out to be - Z3 has a separate operation for each, and the fixed one gives
    # the solver much more to work with, so a literal never goes through the other
    def rotate_left(num)
      return sort.new(LowLevel.mk_ext_rotate_left(self, sort.cast(num))) if num.is_a?(Expr)
      raise Z3::Exception, "Rotation amount must be a nonnegative Integer" unless num.is_a?(Integer) and num >= 0
      sort.new(LowLevel.mk_rotate_left(num, self))
    end

    def rotate_right(num)
      return sort.new(LowLevel.mk_ext_rotate_right(self, sort.cast(num))) if num.is_a?(Expr)
      raise Z3::Exception, "Rotation amount must be a nonnegative Integer" unless num.is_a?(Integer) and num >= 0
      sort.new(LowLevel.mk_rotate_right(num, self))
    end

    def extract(hi, lo)
      raise Z3::Exception, "Trying to extract bits out of range" unless sort.size > hi and hi >= lo and lo >= 0
      BitvecSort.new(hi - lo + 1).new(LowLevel.mk_extract(hi, lo, self))
    end

    def concat(other)
      raise Z3::Exception, "Can only concatenate another Bitvec" unless other.is_a?(BitvecExpr)
      BitvecSort.new(sort.size + other.sort.size).new(LowLevel.mk_concat(self, other))
    end

    # A single bit, as a Bool. Deliberately not #[] - that would read like #extract
    # with a one-bit range, which gives a Bitvec(1) instead
    def bit(index)
      raise Z3::Exception, "Trying to take a bit out of range" unless index.is_a?(Integer) and index.between?(0, sort.size - 1)
      BoolSort.new.new(LowLevel.mk_bit2bool(index, self))
    end

    def repeat(count)
      raise Z3::Exception, "Repeat count must be a positive Integer" unless count.is_a?(Integer) and count >= 1
      BitvecSort.new(sort.size * count).new(LowLevel.mk_repeat(count, self))
    end

    # Z3 answers these with a one-bit Bitvec rather than a Bool, which is what
    # #all_bits_set? and #any_bits_set? are for
    def redand
      BitvecSort.new(1).new(LowLevel.mk_bvredand(self))
    end

    def redor
      BitvecSort.new(1).new(LowLevel.mk_bvredor(self))
    end

    def all_bits_set?
      redand == 1
    end

    def any_bits_set?
      redor == 1
    end

    def to_i
      raise Z3::Exception, "Use #signed_to_i or #unsigned_to_i for Bitvec, not #to_i"
    end

    def signed_to_i
      IntSort.new.new(LowLevel.mk_bv2int(self, true))
    end

    def unsigned_to_i
      IntSort.new.new(LowLevel.mk_bv2int(self, false))
    end

    def zero_ext(size)
      raise Z3::Exception, "Extension size must be a nonnegative Integer" unless size.is_a?(Integer) and size >= 0
      BitvecSort.new(sort.size + size).new(LowLevel.mk_zero_ext(size, self))
    end

    def sign_ext(size)
      raise Z3::Exception, "Extension size must be a nonnegative Integer" unless size.is_a?(Integer) and size >= 0
      BitvecSort.new(sort.size + size).new(LowLevel.mk_sign_ext(size, self))
    end

    def add_no_overflow?(other)
      raise Z3::Exception, "Use #signed_add_no_overflow? or #unsigned_add_no_overflow? for Bitvec, not #add_no_overflow?"
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
      raise Z3::Exception, "Unsigned + can't underflow"
    end

    # Subtraction is addition's mirror image: only signed can overflow, and both
    # signs can underflow - so which of these takes a sign is the other way round
    def sub_no_overflow?(other)
      BitvecExpr.SignedSubNoOverflow(self, other)
    end
    def signed_sub_no_overflow?(other)
      BitvecExpr.SignedSubNoOverflow(self, other)
    end
    def unsigned_sub_no_overflow?(other)
      raise Z3::Exception, "Unsigned - can't overflow"
    end

    def sub_no_underflow?(other)
      raise Z3::Exception, "Use #signed_sub_no_underflow? or #unsigned_sub_no_underflow? for Bitvec, not #sub_no_underflow?"
    end
    def signed_sub_no_underflow?(other)
      BitvecExpr.SignedSubNoUnderflow(self, other)
    end
    def unsigned_sub_no_underflow?(other)
      BitvecExpr.UnsignedSubNoUnderflow(self, other)
    end

    def unsigned_neg_no_overflow?
      raise Z3::Exception, "There is no unsigned negation"
    end
    def signed_neg_no_overflow?
      BitvecExpr.SignedNegNoOverflow(self)
    end
    def neg_no_overflow?
      BitvecExpr.SignedNegNoOverflow(self)
    end

    def mul_no_overflow?(other)
      raise Z3::Exception, "Use signed_mul_no_overflow? or unsigned_mul_no_overflow?"
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
      raise Z3::Exception, "Unsigned * can't underflow"
    end

    def div_no_overflow?(other)
      BitvecExpr.SignedDivNoOverflow(self, other)
    end
    def signed_div_no_overflow?(other)
      BitvecExpr.SignedDivNoOverflow(self, other)
    end
    def unsigned_div_no_overflow?(other)
      raise Z3::Exception, "Unsigned / can't overflow"
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

    def zero?
      self == 0
    end

    def nonzero?
      self != 0
    end

    def positive?
      self.signed_gt 0
    end

    def negative?
      self.signed_lt 0
    end

    def abs
      self.negative?.ite(-self, self)
    end

    def coerce(other)
      other_sort = Expr.sort_for_const(other, toward: sort)
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

      def SignedDiv(a, b)
        a, b = coerce_to_same_bv_sort(a, b)
        a.sort.new(LowLevel.mk_bvsdiv(a, b))
      end

      def UnsignedDiv(a, b)
        a, b = coerce_to_same_bv_sort(a, b)
        a.sort.new(LowLevel.mk_bvudiv(a, b))
      end

      def SignedMod(a, b)
        a, b = coerce_to_same_bv_sort(a, b)
        a.sort.new(LowLevel.mk_bvsmod(a, b))
      end

      def SignedRem(a, b)
        a, b = coerce_to_same_bv_sort(a, b)
        a.sort.new(LowLevel.mk_bvsrem(a, b))
      end

      def UnsignedRem(a, b)
        a, b = coerce_to_same_bv_sort(a, b)
        a.sort.new(LowLevel.mk_bvurem(a, b))
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

      def SignedSubNoOverflow(a, b)
        a, b = coerce_to_same_bv_sort(a, b)
        BoolSort.new.new(LowLevel.mk_bvsub_no_overflow(a, b))
      end

      def SignedSubNoUnderflow(a, b)
        a, b = coerce_to_same_bv_sort(a, b)
        BoolSort.new.new(LowLevel.mk_bvsub_no_underflow(a, b, true))
      end

      def UnsignedSubNoUnderflow(a, b)
        a, b = coerce_to_same_bv_sort(a, b)
        BoolSort.new.new(LowLevel.mk_bvsub_no_underflow(a, b, false))
      end
    end
  end
end
