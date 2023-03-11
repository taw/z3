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

    def to_i
      if ast_kind == :numeral
        LowLevel.get_numeral_string(self).to_i
      else
        obj = simplify
        if obj.ast_kind == :numeral
          LowLevel.get_numeral_string(obj).to_i
        else
          raise Z3::Exception, "Can't convert expression #{to_s} to Integer"
        end
      end
    end

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
