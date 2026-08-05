module Z3
  # Z3 internally represents String as Seq(Char), so StringSort == SeqSort.new(CharSort.new)
  class StringSort < Sort
    def initialize
      super LowLevel.mk_string_sort
    end

    def element_sort
      CharSort.new
    end

    def expr_class
      StringExpr
    end

    # A Z3 string is a sequence of code points, so a Ruby String converts character by
    # character, not byte by byte - which means it has to be valid in its own encoding
    def from_const(val)
      raise cant_convert(val) unless val.is_a?(String)
      raise Z3::Exception, "String is not valid #{val.encoding}" unless val.valid_encoding?
      val.each_codepoint do |code_point|
        next if code_point <= CharSort::MAX_CODE_POINT
        raise Z3::Exception, "Character 0x#{code_point.to_s(16).upcase} is outside Z3's alphabet (0 to 0x#{CharSort::MAX_CODE_POINT.to_s(16).upcase})"
      end
      new(LowLevel.mk_string(val))
    end

    # These live here rather than as `IntExpr#to_str` and friends, because `to_str` is
    # Ruby's implicit String conversion and `to_s` is already every AST's printed form.
    # StringExpr#to_i and #to_code go the other way.

    # The decimal digits of a nonnegative Int. SMT-LIB says a negative number has no
    # string form at all, and Z3 answers "" for one rather than "-1".
    def from_int(int)
      new(LowLevel.mk_int_to_str(IntSort.new.cast(int)))
    end

    # The one character string for a code point, or "" if it isn't one.
    # StringExpr#to_code is this backwards.
    def from_code(int)
      new(LowLevel.mk_string_from_code(IntSort.new.cast(int)))
    end

    # Decimal digits again, but of a Bitvec read either way - the same eight bits
    # give "253" unsigned and "-3" signed
    def from_unsigned_bv(bv)
      new(LowLevel.mk_ubv_to_str(expect_bitvec(bv)))
    end

    def from_signed_bv(bv)
      new(LowLevel.mk_sbv_to_str(expect_bitvec(bv)))
    end

    private

    def expect_bitvec(bv)
      raise Z3::Exception, "Bitvec expected, got #{AST.describe(bv)}" unless bv.is_a?(BitvecExpr)
      bv
    end

    public_class_method :new
  end
end
