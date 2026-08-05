module Z3
  class FloatSort < Sort
    def initialize(e, s=nil)
      if s.nil?
        case e
        when 16
          super LowLevel.mk_fpa_sort_16
        when 32
          super LowLevel.mk_fpa_sort_32
        when 64
          super LowLevel.mk_fpa_sort_64
        when 128
          super LowLevel.mk_fpa_sort_128
        when :half
          super LowLevel.mk_fpa_sort_half
        when :single
          super LowLevel.mk_fpa_sort_single
        when :double
          super LowLevel.mk_fpa_sort_double
        when :quadruple
          super LowLevel.mk_fpa_sort_quadruple
        else
          raise Z3::Exception, "Unknown float type #{e}, use FloatSort.new(exponent_bits, significant_bits)"
        end
      else
        super LowLevel.mk_fpa_sort(e, s)
      end
    end

    def expr_class
      FloatExpr
    end

    def from_const(val)
      if val.is_a?(Integer)
        val_f = val.to_f
        raise Z3::Exception, "Out of range" unless val_f == val
        val = val_f
      elsif !val.is_a?(Float)
        raise cant_convert(val)
      end

      # A Ruby Float is a double, so this is exact for the double sort
      double = FloatSort.new(:double)
      return new(LowLevel.mk_fpa_numeral_double(val, self)) if self == double

      # For every other sort the value has to be rounded, and Z3_mk_fpa_numeral_double
      # gets that wrong - it returns NaN on overflow and misencodes denormals. Build the
      # exact double instead, and let Z3 round it to this sort the way IEEE says to.
      exact = FloatExpr.new(LowLevel.mk_fpa_numeral_double(val, double), double)
      rounding_mode = RoundingModeSort.new.nearest_ties_even
      new(LowLevel.mk_fpa_to_fp_float(rounding_mode, exact, self)).simplify
    end

    # Everything below builds a value of this sort out of some other expression.
    # All but #from_ieee_bv and #from_components round, so they need a rounding mode.

    # Reinterprets the IEEE 754 bits, so it's #to_ieee_bv backwards and nothing is
    # rounded. The Bitvec has to be exactly as wide as this sort.
    def from_ieee_bv(bv)
      expect_bitvec_of_size(bv, ebits + sbits, "an IEEE bit pattern")
      new(LowLevel.mk_fpa_to_fp_bv(bv, self))
    end

    # The three IEEE fields separately, which is #sign_bv / #exponent_bv /
    # #significand_bv backwards. The significand excludes the leading bit IEEE
    # doesn't store, so it's one narrower than `sbits`.
    def from_components(sign, exponent, significand)
      expect_bitvec_of_size(sign, 1, "a sign")
      expect_bitvec_of_size(exponent, ebits, "an exponent")
      expect_bitvec_of_size(significand, sbits - 1, "a significand")
      new(LowLevel.mk_fpa_fp(sign, exponent, significand))
    end

    def from_float(float, mode)
      raise Z3::Exception, "Float expected" unless float.is_a?(FloatExpr)
      new(LowLevel.mk_fpa_to_fp_float(expect_mode(mode), float, self))
    end

    def from_real(real, mode)
      new(LowLevel.mk_fpa_to_fp_real(expect_mode(mode), RealSort.new.cast(real), self))
    end

    # Reads the Bitvec as a number and rounds it to this sort, where #from_ieee_bv
    # reads the very same bits as a float already
    def from_signed_bv(bv, mode)
      raise Z3::Exception, "Bitvec expected" unless bv.is_a?(BitvecExpr)
      new(LowLevel.mk_fpa_to_fp_signed(expect_mode(mode), bv, self))
    end

    def from_unsigned_bv(bv, mode)
      raise Z3::Exception, "Bitvec expected" unless bv.is_a?(BitvecExpr)
      new(LowLevel.mk_fpa_to_fp_unsigned(expect_mode(mode), bv, self))
    end

    # `significand * 2 ** exponent`, with a Real significand and an Int exponent -
    # the one constructor which isn't a conversion from some other representation
    def from_significand_and_exponent(significand, exponent, mode)
      new(LowLevel.mk_fpa_to_fp_int_real(
        expect_mode(mode),
        IntSort.new.cast(exponent),
        RealSort.new.cast(significand),
        self,
      ))
    end

    def >(other)
      raise ArgumentError unless other.is_a?(Sort)
      return true if other.is_a?(IntSort) # This is nasty...
      return true if other.is_a?(RealSort) # This is nasty...
      false
    end

    def ebits
      LowLevel.fpa_get_ebits(self)
    end

    def sbits
      LowLevel.fpa_get_sbits(self)
    end

    def to_s
      "Float(#{ebits}, #{sbits})"
    end

    def inspect
      "FloatSort(#{ebits}, #{sbits})"
    end

    def nan
      new LowLevel.mk_fpa_nan(self)
    end

    def positive_infinity
      new LowLevel.mk_fpa_inf(self, false)
    end

    def negative_infinity
      new LowLevel.mk_fpa_inf(self, true)
    end

    def positive_zero
      new LowLevel.mk_fpa_zero(self, false)
    end

    def negative_zero
      new LowLevel.mk_fpa_zero(self, true)
    end

    private

    def expect_mode(mode)
      raise Z3::Exception, "Mode expected" unless mode.is_a?(RoundingModeExpr)
      mode
    end

    def expect_bitvec_of_size(bv, size, what)
      raise Z3::Exception, "Bitvec(#{size}) expected as #{what}, got #{AST.describe(bv)}" unless
        bv.is_a?(BitvecExpr) and bv.sort.size == size
      bv
    end

    public_class_method :new
  end
end
