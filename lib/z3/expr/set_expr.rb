module Z3
  class SetExpr < Expr
    public_class_method :new

    def element_sort
      sort.element_sort
    end

    def is_superset_of(other)
      SetExpr.Subset(other, self)
    end

    def is_subset_of(other)
      SetExpr.Subset(self, other)
    end

    def complement
      sort.new(LowLevel.mk_set_complement(self))
    end

    def union(other)
      SetExpr.Union(self, other)
    end

    def intersection(other)
      SetExpr.Union(self, other)
    end

    def difference(other)
      SetExpr.Difference(self, other)
    end

    def include?(element)
      element = element_sort.cast(element)
      BoolSort.new.new(LowLevel.mk_set_member(element, self))
    end

    class << self
      def coerce_to_same_set_sort(*args)
        args = coerce_to_same_sort(*args)
        raise Z3::Exception, "Set value with same element sort expected" unless args[0].is_a?(SetExpr)
        args
      end

      def Subset(a, b)
        a, b = coerce_to_same_set_sort(a, b)
        BoolSort.new.new(LowLevel.mk_set_subset(a, b))
      end

      def Union(*args)
        args = coerce_to_same_set_sort(*args)
        args[0].sort.new(LowLevel.mk_set_union(args))
      end

      def Intersection(*args)
        args = coerce_to_same_set_sort(*args)
        args[0].sort.new(LowLevel.mk_set_intersect(args))
      end

      def Difference(a, b)
        a, b = coerce_to_same_set_sort(a, b)
        a.sort.new(LowLevel.mk_set_difference(a, b))
      end
    end
  end
end
