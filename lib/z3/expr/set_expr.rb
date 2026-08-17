module Z3
  class SetExpr < Expr
    include ArrayValue
    public_class_method :new

    def element_sort
      sort.element_sort
    end

    # The Array vocabulary, because a Set *is* an `Array(X, Bool)` and asking for one
    # gives you a Set - see ArraySort.new. `#add` and `#delete` are `#store` with a
    # literal `true` and `false`; `#store` is the only way to say it with a symbolic
    # Bool, so it can't just be dropped. Z3's `select` is `#include?` here, and is not
    # exposed under its own name - Ruby's `select` filters, which this doesn't.
    def key_sort
      sort.key_sort
    end

    def value_sort
      sort.value_sort
    end

    def store(key, value)
      sort.new LowLevel.mk_store(self, element_sort.cast(key), BoolSort.new.cast(value))
    end

    def [](key)
      include?(key)
    end

    # What the set answers for elements nothing has stored to - `true` for a co-finite
    # set, which is the case #value refuses to convert. See ArrayExpr#default.
    def default
      BoolSort.new.new(LowLevel.mk_array_default(self))
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

    # A Ruby Set out of a set value, with #value called on every element.
    #
    # A Z3 set is an Array to Bool, so it's just as happy holding everything except a
    # few elements as it is holding a few - and a solver asked for no more than "3 is
    # in it, 5 isn't" will quite reasonably answer "everything except 5". Ruby has no
    # co-finite set, so that case raises rather than lying about what Z3 said, and
    # #complement is how you ask which elements it leaves out.
    def value
      chain = store_chain || simplify.store_chain
      raise Z3::Exception, "Can't convert expression #{self} into Set" unless chain
      default, stores = chain
      raise Z3::Exception, "Can't convert expression #{self} into Set, it holds all but finitely many #{element_sort} values - #complement.value are the ones it leaves out" if default.value
      members = stores.each_with_object({}) { |(element, member), h| h[element.value] = member.value }
      Set.new(members.select { |_, member| member }.keys)
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
