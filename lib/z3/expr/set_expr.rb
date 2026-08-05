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
      SetExpr.Intersection(self, other)
    end

    def difference(other)
      SetExpr.Difference(self, other)
    end

    def include?(element)
      element = element_sort.cast(element)
      BoolSort.new.new(LowLevel.mk_set_member(element, self))
    end

    # A new set with the element in it, the way #union gives a new set - Ruby's
    # Set#add mutates the receiver, but no Z3 expression is ever mutable.
    # (`mk_set_add` takes the set first, where `mk_set_member` above takes the element
    # first. Z3's own inconsistency, not ours.)
    def add(element)
      sort.new(LowLevel.mk_set_add(self, element_sort.cast(element)))
    end

    # Same, without the element. Removing something which was never there is fine.
    def delete(element)
      sort.new(LowLevel.mk_set_del(self, element_sort.cast(element)))
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
