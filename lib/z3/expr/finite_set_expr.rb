module Z3
  # A value of a FiniteSetSort, which reads like Ruby's Set - see that sort for how it
  # differs from SetExpr, which reads like one too and is a different Z3 sort.
  #
  # Where Ruby's Set mutates, this returns a new expression: no Z3 expression is ever
  # mutable, so `#add` and `#delete` build a new set the way `#union` does. `#<<` is
  # deliberately absent for that reason - in Ruby it's the mutating spelling of #add,
  # and one that quietly didn't mutate would be worse than not having it.
  class FiniteSetExpr < Expr
    # Z3 versions which hang on `set.map`, each with the first version that doesn't.
    # `nil` means no version is known to work yet, so #map refuses on all of them -
    # see there for what "hang" means here and why refusing is the only option.
    #
    # Same shape as `Simplifier::UNSOUND`, and for the same reason: the gem supports
    # Z3 versions on both sides of a fix, so the entry stays after the fix lands and
    # the predicate decides. `spec/upstream_bugs_spec.rb` is what will notice.
    MAP_HANGS = {fixed_in: nil}

    public_class_method :new

    def element_sort
      sort.element_sort
    end

    # Ruby's Set#size / #length / #count. `#count` only in its no-argument form -
    # Ruby's takes a block or a value, and Z3 counts the whole set or nothing.
    def size
      IntSort.new.new(LowLevel.mk_finite_set_size(self))
    end

    alias_method :length, :size

    def count
      size
    end

    # Deliberately `== Empty` and not `size == 0`. They mean the same thing, but Z3's
    # cardinality reasoning is unsound (see FiniteSetSort) and unstable with it - the
    # same `size == 0` question comes back `:sat` or `:unsat` depending on what else
    # the solver has seen. Equality against the empty set is decided correctly, so
    # nothing here is built on `#size` that doesn't have to be.
    def empty?
      self == sort.Empty
    end

    # Ruby's Set#include? / #member?
    def include?(element)
      BoolSort.new.new(LowLevel.mk_finite_set_member(element_sort.cast(element), self))
    end

    alias_method :member?, :include?

    # A new set with the element in it, the way #union gives a new set. Ruby's
    # Set#add mutates and returns the set; this can't and doesn't.
    def add(element)
      union(sort.Singleton(element))
    end

    # Same, without the element. Removing something which was never there is fine,
    # as it is in Ruby.
    def delete(element)
      difference(sort.Singleton(element))
    end

    def union(other)
      FiniteSetExpr.Union(self, other)
    end

    def intersection(other)
      FiniteSetExpr.Intersection(self, other)
    end

    def difference(other)
      FiniteSetExpr.Difference(self, other)
    end

    # Ruby's Set#^ - in one or the other but not both
    def ^(other)
      other = sort.cast(other)
      union(other).difference(intersection(other))
    end

    alias_method :|, :union
    alias_method :+, :union
    alias_method :&, :intersection
    alias_method :-, :difference

    # Ruby's Set#subset? and friends. Z3's `set.subset` is `⊆`, so `#subset?` and
    # `#<=` are it directly, and the proper forms add the inequality.
    def subset?(other)
      FiniteSetExpr.Subset(self, other)
    end

    def superset?(other)
      FiniteSetExpr.Subset(other, self)
    end

    # Proper is subset-and-not-equal. Not "and smaller", which would say the same thing
    # through `#size` - see #empty? for why nothing here goes near that if it can help it.
    def proper_subset?(other)
      other = sort.cast(other)
      subset?(other) & ~(self == other)
    end

    def proper_superset?(other)
      other = sort.cast(other)
      superset?(other) & ~(self == other)
    end

    alias_method :<=, :subset?
    alias_method :>=, :superset?
    alias_method :<, :proper_subset?
    alias_method :>, :proper_superset?

    # Ruby's Set#disjoint? / #intersect?
    def disjoint?(other)
      intersection(other).empty?
    end

    def intersect?(other)
      ~disjoint?(other)
    end

    # Ruby's Set#map. The block gets an element and returns one, and the result is a
    # set of whatever sort it returned - so mapping a FiniteSet(Int) through a
    # predicate gives a FiniteSet(Bool), which has at most two elements however big
    # the set was.
    #
    # Instead of a block you can pass a `Z3.Lambda`, which is what the block builds.
    #
    # Refused on every Z3 that has finite sets, because asking one anything hangs.
    # `Set[1, 2].map { |x| x * 10 }.include?(10)` does not return, and neither
    # `timeout` nor `rlimit` cuts it short - Z3 never looks at either from inside that
    # loop - so there's no way to recover and nothing to hand back. Even `map == map`
    # on two identical terms hangs. Building the term and refusing to say so would
    # only move the hang to whichever #check came next.
    #
    # #select is the one that works: it's incomplete, answering `:unknown` more often
    # than not, but it always answers.
    def map(function = nil, &block)
      unless MAP_HANGS[:fixed_in] and Z3.version_at_least?(*MAP_HANGS[:fixed_in])
        raise Z3::Exception, "Z3 #{Z3.version} hangs on any query about set.map rather " \
                             "than answering or giving up, so #map is refused - it would " \
                             "build a term that stops the first #check which reaches it. " \
                             "#select works, if a subset is what you needed."
      end
      function = unary_function("#map", function, &block)
      range = function.is_a?(SetExpr) ? BoolSort.new : function.sort.value_sort
      FiniteSetSort.new(range).new(LowLevel.mk_finite_set_map(function, self))
    end

    alias_method :collect, :map

    # Ruby's Set#select / #filter. The block returns a Bool, and the result is the
    # subset it holds for.
    def select(function = nil, &block)
      function = unary_function("#select", function, &block)
      unless function.is_a?(SetExpr)
        raise Z3::Exception, "#select wants a function to Bool, got one to #{function.sort.value_sort}"
      end
      sort.new(LowLevel.mk_finite_set_filter(function, self))
    end

    alias_method :filter, :select

    # A Ruby Set out of a set value, with #value called on every element - so a
    # FiniteSet(FiniteSet(Int)) gives nested Sets.
    #
    # This works the term out in Ruby rather than asking Z3, because Z3 5.0 won't do
    # it: neither its evaluator nor its simplifier reduces a `set.union` of concrete
    # singletons, so there's nothing to ask. See `spec/upstream_bugs_spec.rb`.
    #
    # Raises for a set the solver never pinned down. Z3 writes one it didn't have to
    # decide as `set.unique`, meaning "some set of this size", and there is no Ruby
    # Set that is - the same reason SetExpr#value refuses a co-finite set.
    def value
      elements = set_elements || simplify.set_elements
      return Set.new(elements.map(&:value)) if elements
      if unpinned?
        raise Z3::Exception, "Can't convert expression #{self} into Set, the solver " \
                             "settled how many elements it has without deciding which - " \
                             "constrain the elements, or ask #size"
      end
      raise Z3::Exception, "Can't convert expression #{self} into Set"
    end

    class << self
      def coerce_to_same_finite_set_sort(*args)
        args = coerce_to_same_sort(*args)
        raise Z3::Exception, "FiniteSet value with same element sort expected" unless args[0].is_a?(FiniteSetExpr)
        args
      end

      # Z3's union, intersection and difference are all binary, so more than two
      # arguments fold. Difference isn't associative, so it folds left and left only -
      # `a - b - c`, which is what the Ruby operator does too.
      def Union(*args)
        fold(:mk_finite_set_union, "Union", args)
      end

      def Intersection(*args)
        fold(:mk_finite_set_intersect, "Intersection", args)
      end

      def Difference(*args)
        fold(:mk_finite_set_difference, "Difference", args)
      end

      def Subset(a, b)
        a, b = coerce_to_same_finite_set_sort(a, b)
        BoolSort.new.new(LowLevel.mk_finite_set_subset(a, b))
      end

      private

      def fold(call, name, args)
        raise Z3::Exception, "#{name} requires at least one argument" if args.empty?
        args = coerce_to_same_finite_set_sort(*args)
        args.inject { |a, b| a.sort.new(LowLevel.public_send(call, a, b)) }
      end
    end

    protected

    # The elements of a set value, or nil for anything which isn't one. Z3 has no set
    # literal - a value is `set.empty`, a `set.singleton`, a union of those, or a
    # `set.range` - and models nest unions any which way and at any arity, so the
    # whole spine gets walked.
    #
    # Intersection and difference are here because a model can hand one back, and both
    # are decidable once every leaf is. Anything else - a variable, a `set.map`, a
    # `set.unique` - has no elements to give and stops the walk.
    def set_elements
      return nil unless ast_kind == :app
      case func_decl.name
      when "set.empty"
        []
      when "set.singleton"
        arguments
      when "set.union"
        combine(:|)
      when "set.intersect"
        combine(:&)
      when "set.difference"
        combine(:-)
      when "set.range"
        range_elements
      end
    end

    # Whether Z3 wrote a set it only had to decide the size of. It spells one
    # `set.unique(id, size)`, meaning "some set of this many elements" - which is a
    # perfectly good answer to a question that didn't say what the elements are, and
    # not a set Ruby has.
    #
    # Matched by name because there's nothing else to match on: `set.unique`'s decl
    # kind is `Z3_OP_INTERNAL`, one past the end of the documented `Z3_OP_FINITE_SET_*`
    # range, so the C API offers no way to ask about it.
    def unpinned?
      return false unless ast_kind == :app
      return true if func_decl.name == "set.unique"
      arguments.any? { |argument| argument.is_a?(FiniteSetExpr) and argument.unpinned? }
    end

    private

    # Set operations on the elements themselves. Z3 hash-conses ASTs, so two numerals
    # of the same value are one pointer and AST#eql? matches them - which is what lets
    # Ruby's own Array#| and friends do the work.
    def combine(operator)
      # Not `map(&:set_elements)` - Symbol#to_proc calls it as a public method, and
      # this one is protected
      arguments.map { |argument| argument.set_elements }.inject do |a, b|
        return nil unless a and b
        a.public_send(operator, b)
      end
    end

    # `set.range` is over Ints, and it's only a value when both ends are literals -
    # `(set.range 1 n)` is a perfectly good term and no particular set.
    def range_elements
      low, high = arguments.map { |end_| end_.ast_kind == :numeral ? end_.value : nil }
      return nil unless low and high
      (low..high).map { |i| IntSort.new.from_const(i) }
    end

    # A one argument function over the element sort, from a block or ready made.
    # Exactly SeqMapFold's, and split out from it for the same reason: a lambda to
    # Bool is an `Array(X, Bool)`, which this gem hands back as a SetExpr, so both
    # classes have to be accepted and the range read from whichever it is.
    def unary_function(method, function, &block)
      if block
        raise Z3::Exception, "Pass a function or a block, not both" if function
        var = element_sort.fresh_var("x")
        return Z3.Lambda(var, block.call(var))
      end
      raise Z3::Exception, "#{method} needs a function or a block" unless function
      ok = case function
      when SetExpr then function.sort.element_sort == element_sort
      when ArrayExpr then function.sort.key_sort == element_sort
      else false
      end
      unless ok
        raise Z3::Exception, "#{method} wants a one argument function over #{element_sort}, got #{AST.describe(function)}"
      end
      function
    end
  end
end
