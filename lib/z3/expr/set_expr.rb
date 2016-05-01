module Z3
  class SetExpr < Expr
    public_class_method :new

    def is_superset_of(other)
    end

    def is_subset_of(other)
    end

    def complement
    end

    def union(other)
    end

    def difference(other)
    end

    class << self
      def coerce_to_same_bv_sort(*args)
        args = coerce_to_same_sort(*args)
        raise Z3::Exception, "Bitvec value with same size expected" unless args[0].is_a?(BitvecExpr)
        args
      end

      def Subset(a, b)
        a, b = coerce_to_same_set_sort(a, b)
        BoolSort.new.mk_set_subset(a, b)
      end

      def Union(a, b)
      end
    end
  end
end
