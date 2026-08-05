module Z3
  class IntExpr < ArithExpr
    def mod(other)
      IntExpr.Mod(self, other)
    end

    def %(other)
      IntExpr.Mod(self, other)
    end

    def rem(other)
      IntExpr.Rem(self, other)
    end

    # Takes the low `size` bits, so it wraps rather than failing on values which
    # don't fit - `Z3.Int("a").to_bv(8)` of 256 is 0. Which Integer comes back out
    # depends on how you read it again: #signed_to_int or #unsigned_to_int.
    # Z3 spells this the other way round, as "other divides self"
    def divisible_by?(other)
      BoolSort.new.new(LowLevel.mk_divides(IntSort.new.cast(other), self))
    end

    def to_bv(size)
      BitvecSort.new(size).new(LowLevel.mk_int2bv(size, self))
    end

    def to_i
      if ast_kind == :numeral
        LowLevel.get_numeral_string(self).to_i
      else
        obj = simplify
        if obj.ast_kind == :numeral
          LowLevel.get_numeral_string(obj).to_i
        else
          raise Z3::Exception, "Can't convert expression #{to_s} into Integer"
        end
      end
    end

    # Every sort which can hand back a Ruby object spells it #value. On Int the two
    # are the same method - converting an Int to an Int is nothing, so #to_i can only
    # ever have meant this - but on the other sorts #to_i builds a Z3 Int expression
    # and it's #value which leaves Z3 entirely.
    alias_method :value, :to_i

    public_class_method :new
    class << self
      def coerce_to_same_int_sort(*args)
        args = coerce_to_same_sort(*args)
        raise Z3::Exception, "Int value expected" unless args[0].is_a?(IntExpr)
        args
      end

      def Mod(a, b)
        a, b = coerce_to_same_int_sort(a, b)
        a.sort.new(LowLevel.mk_mod(a, b))
      end

      def Rem(a, b)
        a, b = coerce_to_same_int_sort(a, b)
        a.sort.new(LowLevel.mk_rem(a, b))
      end
    end
  end
end
