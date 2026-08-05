module Z3
  class CharSort < Sort
    def initialize
      super LowLevel.mk_char_sort
    end

    # Z3's alphabet is Unicode code points 0 to 0x2FFFF, so it stops short of
    # Ruby's 0x10FFFF. Z3 itself doesn't check, it just misbehaves.
    MAX_CODE_POINT = 0x2FFFF

    def expr_class
      CharExpr
    end

    # Ruby has no character type, so a Char can be built either from a code point
    # or from a one character String
    def from_const(val)
      case val
      when Integer
        raise Z3::Exception, "Char code point must be between 0 and 0x#{MAX_CODE_POINT.to_s(16).upcase}" unless (0..MAX_CODE_POINT).cover?(val)
        new(LowLevel.mk_char(val))
      when String
        raise Z3::Exception, "Only single character strings can be converted to Char" unless val.size == 1
        from_const(val.ord)
      else
        raise cant_convert(val)
      end
    end

    # The other direction of CharExpr#to_bv. Z3 wants the full 18 bits, which is as
    # wide as its alphabet goes.
    def from_bv(bv)
      raise Z3::Exception, "Bitvec(18) expected, got #{AST.describe(bv)}" unless
        bv.is_a?(BitvecExpr) and bv.sort.size == 18
      new(LowLevel.mk_char_from_bv(bv))
    end

    def to_s
      "Char"
    end

    public_class_method :new
  end
end
