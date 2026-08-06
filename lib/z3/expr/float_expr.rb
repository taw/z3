module Z3
  class FloatExpr < Expr

    def ==(other)
      FloatExpr.Eq(self, other)
    end

    def !=(other)
      FloatExpr.Ne(self, other)
    end

    def <(other)
      FloatExpr.Lt(self, other)
    end

    def <=(other)
      FloatExpr.Le(self, other)
    end

    def >(other)
      FloatExpr.Gt(self, other)
    end

    def >=(other)
      FloatExpr.Ge(self, other)
    end

    def add(other, mode)
      FloatExpr.Add(self, other, mode)
    end

    def sub(other, mode)
      FloatExpr.Sub(self, other, mode)
    end

    def mul(other, mode)
      FloatExpr.Mul(self, other, mode)
    end

    def div(other, mode)
      FloatExpr.Div(self, other, mode)
    end

    def rem(other)
      FloatExpr.Rem(self, other)
    end

    def sqrt(mode)
      FloatExpr.Sqrt(self, mode)
    end

    # Nearest float with no fractional part, rounded `mode`'s way - so which of 2.0
    # and 3.0 you get for 2.5 is the rounding mode's business, not this method's
    def round_to_integral(mode)
      FloatExpr.RoundToIntegral(self, mode)
    end

    # `(self * other) + addend`, rounded once at the end rather than after the
    # multiply and again after the add
    def fused_multiply_add(other, addend, mode)
      FloatExpr.FusedMultiplyAdd(self, other, addend, mode)
    end

    def abs
      sort.new LowLevel.mk_fpa_abs(self)
    end

    def -@
      sort.new LowLevel.mk_fpa_neg(self)
    end

    def infinite?
      BoolSort.new.new LowLevel.mk_fpa_is_infinite(self)
    end

    def nan?
      BoolSort.new.new LowLevel.mk_fpa_is_nan(self)
    end

    def negative?
      BoolSort.new.new LowLevel.mk_fpa_is_negative(self)
    end

    def normal?
      BoolSort.new.new LowLevel.mk_fpa_is_normal(self)
    end

    def positive?
      BoolSort.new.new LowLevel.mk_fpa_is_positive(self)
    end

    def subnormal?
      BoolSort.new.new LowLevel.mk_fpa_is_subnormal(self)
    end

    def zero?
      BoolSort.new.new LowLevel.mk_fpa_is_zero(self)
    end

    def nonzero?
      Z3.And(~zero?, ~nan?)
    end

    def max(other)
      FloatExpr.Max(self, other)
    end

    def min(other)
      FloatExpr.Min(self, other)
    end

    # Exact - a Real can hold every float value, where the other direction rounds.
    # Z3 leaves the answer unspecified for NaN and the infinities.
    def to_real
      RealSort.new.new(LowLevel.mk_fpa_to_real(self))
    end

    # The IEEE 754 bits of this float, as one Bitvec of the sort's full width.
    # NaN has many encodings and Z3 doesn't promise which one you get.
    def to_ieee_bv
      BitvecSort.new(sort.ebits + sort.sbits).new(LowLevel.mk_fpa_to_ieee_bv(self))
    end

    # Rounding to an integer, unlike #to_ieee_bv which reinterprets the bits.
    # Z3 leaves the answer unspecified when the value doesn't fit in `size` bits.
    def to_bv(*)
      raise Z3::Exception, "Use #to_signed_bv or #to_unsigned_bv for Float, not #to_bv"
    end

    def to_signed_bv(size, mode)
      BitvecSort.new(size).new(LowLevel.mk_fpa_to_sbv(FloatExpr.coerce_to_mode_sort(mode), self, size))
    end

    def to_unsigned_bv(size, mode)
      BitvecSort.new(size).new(LowLevel.mk_fpa_to_ubv(FloatExpr.coerce_to_mode_sort(mode), self, size))
    end

    def exponent_string(biased)
      LowLevel.fpa_get_numeral_exponent_string(self, biased)
    end

    def significand_string
      LowLevel.fpa_get_numeral_significand_string(self)
    end

    # The same three pieces as #exponent_string and #significand_string, but as Bitvec
    # expressions rather than Ruby Strings. Like those, they only work on a literal.
    # The significand is one bit narrower than the sort's `sbits` - IEEE doesn't store
    # the leading bit.
    def sign_bv
      BitvecSort.new(1).new(LowLevel.fpa_get_numeral_sign_bv(self))
    end

    def exponent_bv(biased)
      BitvecSort.new(sort.ebits).new(LowLevel.fpa_get_numeral_exponent_bv(self, biased))
    end

    def significand_bv
      BitvecSort.new(sort.sbits - 1).new(LowLevel.fpa_get_numeral_significand_bv(self))
    end

    # Leaves Z3 for a Ruby Float, where #to_real and #to_ieee_bv build expressions.
    # A Ruby Float is an IEEE double, so every Float(11, 53) or narrower value
    # converts exactly, NaN, the infinities and the two zeroes included.
    #
    # A wider sort raises whatever it holds, even when that value happens to fit -
    # Float(15, 113)'s 1.5 is a double's 1.5, but a sort which can't round-trip
    # through a Float doesn't get a #value which works only sometimes.
    def value
      unless sort.ebits <= 11 and sort.sbits <= 53
        raise Z3::Exception, "#{sort} values don't fit in a Ruby Float, which is an IEEE double - only Float(11, 53) and narrower have a #value, use #to_real or #significand_string / #exponent_string"
      end

      obj = as_literal
      # Deliberately not #nan? / #infinite? / #zero?, which build symbolic BoolExprs -
      # these ask about the literal in Ruby, and #value is the only thing that needs it
      return Float::NAN if LowLevel.fpa_is_numeral_nan(obj)
      sign = LowLevel.fpa_is_numeral_negative(obj) ? -1 : 1
      return sign * Float::INFINITY if LowLevel.fpa_is_numeral_inf(obj)
      return sign * 0.0 if LowLevel.fpa_is_numeral_zero(obj)

      # Z3's significand is in [0, 2) and its unbiased exponent stays at the sort's
      # minimum for subnormals, so one expression covers normal and subnormal alike.
      # Both strings are exact, and the sort check above means the double is too.
      exact = sign * Rational(obj.significand_string) * 2 ** obj.exponent_string(false).to_i
      exact.to_f
    end

    public_class_method :new

    class << self
      def coerce_to_same_float_sort(*args)
        args = coerce_to_same_sort(*args)
        raise Z3::Exception, "Float value with same sizes expected" unless args[0].is_a?(FloatExpr)
        args
      end

      def coerce_to_mode_sort(m)
        raise Z3::Exception, "Mode expected" unless m.is_a?(RoundingModeExpr)
        m
      end

      def Eq(a, b)
        a, b = coerce_to_same_float_sort(a, b)
        BoolSort.new.new(LowLevel.mk_fpa_eq(a, b))
      end

      def Ne(a, b)
        ~Eq(a,b)
      end

      def Gt(a, b)
        a, b = coerce_to_same_float_sort(a, b)
        BoolSort.new.new(LowLevel.mk_fpa_gt(a, b))
      end

      def Lt(a, b)
        a, b = coerce_to_same_float_sort(a, b)
        BoolSort.new.new(LowLevel.mk_fpa_lt(a, b))
      end

      def Ge(a, b)
        a, b = coerce_to_same_float_sort(a, b)
        BoolSort.new.new(LowLevel.mk_fpa_geq(a, b))
      end

      def Le(a, b)
        a, b = coerce_to_same_float_sort(a, b)
        BoolSort.new.new(LowLevel.mk_fpa_leq(a, b))
      end

      def Add(a, b, m)
        a, b = coerce_to_same_float_sort(a, b)
        m = coerce_to_mode_sort(m)
        a.sort.new(LowLevel.mk_fpa_add(m, a, b))
      end

      def Sub(a, b, m)
        a, b = coerce_to_same_float_sort(a, b)
        m = coerce_to_mode_sort(m)
        a.sort.new(LowLevel.mk_fpa_sub(m, a, b))
      end

      def Mul(a, b, m)
        a, b = coerce_to_same_float_sort(a, b)
        m = coerce_to_mode_sort(m)
        a.sort.new(LowLevel.mk_fpa_mul(m, a, b))
      end

      def Div(a, b, m)
        a, b = coerce_to_same_float_sort(a, b)
        m = coerce_to_mode_sort(m)
        a.sort.new(LowLevel.mk_fpa_div(m, a, b))
      end

      def Rem(a, b)
        a, b = coerce_to_same_float_sort(a, b)
        a.sort.new(LowLevel.mk_fpa_rem(a, b))
      end

      # In older versons, this dies when trying to calll Z3_get_ast_kind, min works on same call
      # Works in 4.6
      def Max(a, b)
        a, b = coerce_to_same_float_sort(a, b)
        a.sort.new(LowLevel.mk_fpa_max(a, b))
      end

      def Min(a, b)
        a, b = coerce_to_same_float_sort(a, b)
        a.sort.new(LowLevel.mk_fpa_min(a, b))
      end

      def Sqrt(a, m)
        m = coerce_to_mode_sort(m)
        a.sort.new(LowLevel.mk_fpa_sqrt(m, a))
      end

      def RoundToIntegral(a, m)
        m = coerce_to_mode_sort(m)
        a.sort.new(LowLevel.mk_fpa_round_to_integral(m, a))
      end

      def FusedMultiplyAdd(a, b, c, m)
        a, b, c = coerce_to_same_float_sort(a, b, c)
        m = coerce_to_mode_sort(m)
        a.sort.new(LowLevel.mk_fpa_fma(m, a, b, c))
      end
    end

    private

    # Every float literal is an `:app`, NaN and the infinities included, so #ast_kind
    # is no help here the way it is on Int and Bitvec - Z3 has a separate question
    def as_literal
      return self if LowLevel.fpa_is_numeral(self)
      simplified = simplify
      unless LowLevel.fpa_is_numeral(simplified)
        raise Z3::Exception, "Can't convert expression #{self} into a Float"
      end
      simplified
    end
  end
end
