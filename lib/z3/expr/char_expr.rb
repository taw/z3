module Z3
  class CharExpr < Expr
    # The code point, as a Z3 Int - `CharSort.new.from_const("a").to_i` is 97.
    # Not a Ruby Integer: that would be #value, and there isn't one, because Ruby
    # has no character type for it to return.
    def to_i
      IntSort.new.new(LowLevel.mk_char_to_int(self))
    end

    # Z3's alphabet stops at 0x2FFFF, which is why 18 bits is always enough
    def to_bv
      BitvecSort.new(18).new(LowLevel.mk_char_to_bv(self))
    end

    def digit?
      BoolSort.new.new(LowLevel.mk_char_is_digit(self))
    end

    # Z3 only gives us `char.<=`, and the order is total, so the other three are
    # that one turned around and negated.
    #
    # Unlike `==`, these take a Ruby String or code point on the right. `Expr.Eq`
    # goes through the generic coercion, which has no way to guess that "a" means a
    # Char rather than a String, while these know their own sort and can just cast.
    def <=(other)
      BoolSort.new.new(LowLevel.mk_char_le(self, sort.cast(other)))
    end

    def >=(other)
      BoolSort.new.new(LowLevel.mk_char_le(sort.cast(other), self))
    end

    def <(other)
      ~(self >= other)
    end

    def >(other)
      ~(self <= other)
    end

    public_class_method :new
  end
end
