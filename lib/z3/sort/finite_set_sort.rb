module Z3
  # A set in the sense Ruby's Set is one - it has a size, and it holds finitely many
  # elements and no more.
  #
  # This is not `SetSort`, and the two are not interchangeable. A `Set(X)` is an
  # `Array(X, Bool)`, a characteristic function: it has no cardinality, and it's just
  # as happy holding everything except 5 as it is holding 3 and 5. A `FiniteSet(X)` is
  # a value with `set.size`, and it maps and filters. When in doubt this is the one you
  # want; `SetSort` is what SMT-LIB has always called an array to Bool.
  #
  # New in Z3 5.0, and Z3's implementation of it is not finished. Two things to know
  # before relying on this sort, both pinned in `spec/upstream_bugs_spec.rb`:
  #
  # * **`#size` is unsound.** Z3 doesn't connect element distinctness to cardinality,
  #   so it answers `:sat` to `set == Set[1, 2] and set.size == 1`, and hands back
  #   `Set[1, 2]` as the model - a model which contradicts the constraint it was asked
  #   to satisfy. Membership, subset and equality between spelled-out sets are all
  #   sound; it's `set.size` that isn't. On Z3 5.1 it's worse than unsound: the same
  #   question about a set whose elements Z3 can see takes the whole process down.
  # * **`#Range` is unsound under `==` once an end is symbolic.** Z3 will agree that
  #   `(1..n)` is `Set[1, 2, 3]` while refusing to let `n` be 3. Asking about
  #   membership instead is sound, and so is `==` with both ends literal.
  # * **Nothing evaluates.** Z3's model evaluator and its simplifier both refuse the
  #   finite set operations, even on fully concrete sets, so `Model#[]` can't reduce
  #   one. `FiniteSetExpr#value` works the term out in Ruby instead, which is why it
  #   exists in the shape it does.
  # * **`set.map` hangs Z3**, uninterruptibly, so `FiniteSetExpr#map` refuses to build
  #   one. See there. `#select` works.
  #
  # None of that touches the parts most programs want: membership, subset, union,
  # intersection, difference and equality against a Ruby Set are all sound and fast.
  class FiniteSetSort < Sort
    attr_reader :element_sort

    def initialize(element_sort)
      # Z3 4.x has none of the `Z3_mk_finite_set_*` entry points, and calling one there
      # raises "Could not find Z3_mk_finite_set_sort in the Z3 library", which says what
      # happened but not what to do about it. This is the only door into the sort, so
      # it's the one place that has to check - everything else needs a FiniteSetSort
      # in hand before it can be reached.
      unless Sort.finite_sets?
        raise Z3::Exception, "Finite sets need Z3 5.0 or newer, this is Z3 #{Z3.version}"
      end
      raise Z3::Exception, "Sort expected, got #{AST.describe(element_sort)}" unless element_sort.is_a?(Sort)
      @element_sort = element_sort
      super LowLevel.mk_finite_set_sort(element_sort)
    end

    def expr_class
      FiniteSetExpr
    end

    def to_s
      "FiniteSet(#{element_sort})"
    end

    def inspect
      "FiniteSetSort(#{element_sort})"
    end

    def Empty
      new(LowLevel.mk_finite_set_empty(self))
    end

    # The one element set, which is what every other set value is built out of -
    # Z3 has no set literal, only `set.empty`, `set.singleton` and `set.union`.
    def Singleton(element)
      new(LowLevel.mk_finite_set_singleton(element_sort.cast(element)))
    end

    # Every Integer from `low` to `high`, both included - `Range(1, 3)`, or `Range(1..3)`
    # for the same thing. Z3 builds this as one `set.range` term rather than as a union
    # of `high - low + 1` singletons, so the ends may be symbolic, which is the whole
    # reason it exists.
    #
    # A Ruby Range is accepted *here*, as a pair of ends, and nowhere else. It isn't a
    # set value: `Set[1, 2, 3] != (1..3)` in Ruby, and there's no reason for them to be
    # the same thing in Z3 when they aren't in Ruby. `[*1..3]` is how you spell a Range
    # as a set.
    #
    # Ints only. Z3 answers anything else with a bare "Sort mismatch for function
    # 'set.range'", which doesn't say which sort was wrong or that Int was wanted.
    def Range(low, high = nil)
      unless element_sort == IntSort.new
        raise Z3::Exception, "Only #{FiniteSetSort.new(IntSort.new)} has ranges, #{self} has no order to take one along"
      end
      low, high = ends_of(low) if high.nil?
      int = IntSort.new
      new(LowLevel.mk_finite_set_range(int.cast(low), int.cast(high)))
    end

    # A Ruby Set or an Array builds a set value, and both mean the same thing -
    # `Set[1, 2]` and `[1, 2]` are the same set, and which one you write is a matter of
    # what's to hand.
    #
    # A duplicate is not an error, in a Set it never can be: `[1, 1]` is `Set[1]`, and
    # the duplicate is dropped here rather than being handed to Z3, which would build a
    # union of two identical singletons and then have to reason it back down to one.
    def from_const(v)
      case v
      when ::Set, Array
        from_elements(v.to_a)
      else
        raise cant_convert(v)
      end
    end

    public_class_method :new

    private

    # The two ends of `Range(1..3)`'s one argument. An exclusive Range gives back the
    # last element it does include, since `set.range` has no exclusive form.
    def ends_of(range)
      unless range.is_a?(::Range)
        raise Z3::Exception, "#{self}#Range takes two ends or one Range, got #{AST.describe(range)}"
      end
      # A set is finite, so an end which isn't there is no end at all
      if range.begin.nil? or range.end.nil?
        raise Z3::Exception, "#{self}#Range needs a Range with both ends, got #{range.inspect}"
      end
      [range.begin, range.exclude_end? ? range.end - 1 : range.end]
    end

    # Z3 has no n-ary union to build - `Z3_mk_finite_set_union` is binary - so a set
    # of n elements is n - 1 nested unions. Models hand them back n-ary anyway, which
    # is why FiniteSetExpr#value walks whatever arity it finds.
    def from_elements(elements)
      elements = elements.map { |element| element_sort.cast(element) }.uniq
      return self.Empty if elements.empty?
      elements.map { |element| new(LowLevel.mk_finite_set_singleton(element)) }
        .inject { |a, b| new(LowLevel.mk_finite_set_union(a, b)) }
    end
  end
end
