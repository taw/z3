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

    def max(other)
      FloatExpr.Max(self, other)
    end

    def min(other)
      FloatExpr.Min(self, other)
    end

    def exponent_string
      LowLevel.fpa_get_numeral_exponent_string(self)
    end

    def significand_string
      LowLevel.fpa_get_numeral_significand_string(self)
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
    end
  end
end
