module Z3
  class BoolExpr < Expr
    def ~
      sort.new(LowLevel.mk_not(self))
    end

    def !
      sort.new(LowLevel.mk_not(self))
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

    def iff(other)
      BoolExpr.Iff(self, other)
    end

    def implies(other)
      BoolExpr.Implies(self, other)
    end

    def ite(a, b)
      BoolExpr.IfThenElse(self, a, b)
    end

    def to_b
      s = to_s
      if ast_kind == :app and (s == "true" or s == "false")
        s == "true"
      else
        obj = simplify
        s = obj.to_s
        if ast_kind == :app and (s == "true" or s == "false")
          s == "true"
        else
          raise Z3::Exception, "Can't convert expression #{to_s} to Boolean"
        end
      end
    end

    public_class_method :new

    class << self
      def coerce_to_same_bool_sort(*args)
        args = coerce_to_same_sort(*args)
        raise Z3::Exception, "Bool value expected" unless args[0].is_a?(BoolExpr)
        args
      end

      def Implies(a,b)
        a, b = coerce_to_same_bool_sort(a, b)
        BoolSort.new.new(LowLevel.mk_implies(a, b))
      end

      def Iff(a,b)
        a, b = coerce_to_same_bool_sort(a, b)
        BoolSort.new.new(LowLevel.mk_iff(a, b))
      end

      def IfThenElse(a, b, c)
        a, = coerce_to_same_bool_sort(a)
        b, c = coerce_to_same_sort(b, c)
        b.sort.new(LowLevel.mk_ite(a, b, c))
      end
    end
  end
end
