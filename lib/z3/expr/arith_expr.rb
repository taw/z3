module Z3
  class ArithExpr < Expr
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
      ArithExpr.Div(self, other)
    end

    def **(other)
      ArithExpr.Power(self, other)
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

    def -@
      sort.new(LowLevel.mk_unary_minus(self))
    end

    def abs
      (self < 0).ite(-self, self)
    end

    # Recast so 1 + x:Float
    # is:  (+ 1.0 x)
    # not: (+ (to_real 1) x)
    def coerce(other)
      other_sort = Expr.sort_for_const(other)
      max_sort = [sort, other_sort].max
      [max_sort.from_const(other), max_sort.from_value(self)]
    end

    class << self
      def coerce_to_same_arith_sort(*args)
        args = coerce_to_same_sort(*args)
        raise Z3::Exception, "Int or Real value expected" unless args[0].is_a?(IntExpr) or args[0].is_a?(RealExpr)
        args
      end

      def Div(a,b)
        a, b = coerce_to_same_arith_sort(a, b)
        a.sort.new(LowLevel.mk_div(a, b))
      end

      def Power(a, b)
        # Wait, is this even legitimate that it's I**I and R**R?
        a, b = coerce_to_same_arith_sort(a, b)
        a.sort.new(LowLevel.mk_power(a, b))
      end
    end
  end
end
