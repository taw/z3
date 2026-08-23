module Z3
  describe FiniteSetExpr do
    before { skip "Finite sets were added in Z3 5.0" unless Z3.version_at_least?(5, 0) }

    let(:sort)   { FiniteSetSort.new(IntSort.new) }
    let(:nested) { FiniteSetSort.new(FiniteSetSort.new(IntSort.new)) }
    let(:a) { sort.var("a") }
    let(:b) { sort.var("b") }
    let(:fs_empty) { sort.Empty }

    def set(*elements)
      sort.from_const(elements)
    end

    # The headline of the whole sort: a Ruby Set is a value of it, from either side,
    # and so are the Array and Range spellings of the same thing
    describe "Ruby values" do
      it "compares equal to a Ruby Set, from either side" do
        expect([a == Set[1, 2]]).to have_solution(a => set(1, 2))
        expect([Set[1, 2] == a]).to have_solution(a => set(1, 2))
        expect([a == Set[1, 2], a.include?(3)]).to have_no_solution
      end

      it "takes an Array for the same value" do
        expect([a == [1, 2]]).to have_solution(a => set(1, 2))
        expect([[1, 2] == a]).to have_solution(a => set(1, 2))
      end

      # `eql?`, not `==` - `==` on two Exprs builds an equation, and every equation is
      # truthy, so `expect(a).to eq(b)` would pass for any two expressions at all
      it "a Set and an Array of the same elements build the very same term" do
        expect(sort.cast(Set[1, 2])).to eql(sort.cast([1, 2]))
        expect(sort.cast(Set[1, 2, 3])).to eql(sort.cast([1, 2, 3]))
      end

      # A set doesn't care what order it was written in, but the term does: Z3 has no
      # n-ary union to build, so `[3, 2, 1]` nests its singletons the other way round
      it "keeps the order it was given, which the set itself doesn't care about" do
        expect(sort.cast([1, 2, 3])).to_not eql(sort.cast([3, 2, 1]))
        expect(sort.cast([1, 2, 3])).to be_equivalent_to(sort.cast([3, 2, 1]))
        expect(sort.cast([3, 2, 1]).value).to eq(Set[1, 2, 3])
      end

      # Ruby says `Set[1, 2, 3] != (1..3)`, and so does this - `[*1..3]` is a set,
      # `FiniteSetSort#Range` is a range, and a bare Range is neither
      it "does not take a Range, which is not a set value in Ruby either" do
        expect { a == (1..3) }
          .to raise_error(Z3::Exception, "Range can't be coerced into FiniteSet(Int)")
        expect([a == [*1..3]]).to have_solution(a => set(1, 2, 3))
        expect([a == sort.Range(1, 3)]).to have_solution(a => sort.Range(1, 3))
      end

      it "takes them as arguments too, not only for equality" do
        expect([a.subset?(Set[1, 2, 3]), a == Set[1, 2]]).to have_solution(a => set(1, 2))
        expect([a == (Set[1, 2] | Set[3])]).to have_solution(a => set(1, 2, 3))
        expect([a == Set[1, 2, 3].to_a]).to have_solution(a => set(1, 2, 3))
      end

      it "!= works from either side" do
        expect([a != Set[1, 2], a == Set[1]]).to have_solution(a => set(1))
        expect([Set[1, 2] != a, a == Set[1, 2]]).to have_no_solution
      end

      # An Array is a tuple's fields as well, and which it means is settled by the
      # sort on the other side and never by the Array
      it "an Array still means a tuple's fields when that's what it's meeting" do
        point = TupleSort.new("FiniteSetArrayPoint", x: IntSort.new, y: IntSort.new)
        p = point.var("p")
        expect([p == [1, 2]]).to have_solution(p => point.mk(1, 2))
      end
    end

    describe "#include?" do
      it "asks about an element" do
        expect([set(1, 2).include?(1)]).to have_solution({})
        expect([set(1, 2).include?(3)]).to have_no_solution
        expect([~sort.Empty.include?(1)]).to have_solution({})
      end

      it "is also spelled #member?" do
        expect([set(1, 2).member?(1)]).to have_solution({})
      end

      it "casts into the element sort" do
        expect { a.include?("nope") }
          .to raise_error(Z3::Exception, "Can't convert String into Int")
      end
    end

    describe "#size" do
      # Z3 5.1 takes the whole process down on any size query about a set whose
      # elements it can see - an assertion violation in ast.cpp, or a segfault when
      # the set is ground - so this can't even be asked there. 5.0 answered it. The
      # crash itself is pinned in spec/upstream_bugs_spec.rb.
      it "is the cardinality" do
        skip "Z3 5.1 crashes on a size query about a set with known elements" unless Z3.version_at_least?(5, 2)
        expect([sort.Empty.size == 0]).to have_solution({})
        expect([set(1, 2, 3).size == 3]).to have_solution({})
      end

      it "is also spelled #length and #count" do
        expect(FiniteSetExpr.instance_method(:length)).to eq(FiniteSetExpr.instance_method(:size))
        # #count is not an alias - Ruby's takes a block or a value, and this one only
        # answers the no-argument form - so it's the term that has to match
        expect(set(1, 2).count).to eql(set(1, 2).size)
      end

    end

    # Asked as `== Empty` rather than as `size == 0`, because Z3's cardinality
    # reasoning is unsound and unstable - see spec/upstream_bugs_spec.rb
    describe "#empty?" do
      it "asks whether there is anything in it" do
        expect([sort.Empty.empty?]).to have_solution({})
        expect([set(1).empty?]).to have_no_solution
        expect([a.empty?, a.include?(1)]).to have_no_solution
      end

      it "does not go through #size" do
        expect(a.empty?).to stringify("a = Set[]")
      end
    end

    describe "set operations" do
      it "union" do
        expect([a == set(1, 2).union(set(2, 3))]).to have_solution(a => set(1, 2, 3))
        expect([a == (set(1) | set(2))]).to have_solution(a => set(1, 2))
        expect([a == (set(1) + set(2))]).to have_solution(a => set(1, 2))
      end

      it "intersection" do
        expect([a == set(1, 2).intersection(set(2, 3))]).to have_solution(a => set(2))
        expect([a == (set(1, 2) & set(2, 3))]).to have_solution(a => set(2))
      end

      it "difference" do
        expect([a == set(1, 2).difference(set(2, 3))]).to have_solution(a => set(1))
        expect([a == (set(1, 2) - set(2))]).to have_solution(a => set(1))
      end

      it "symmetric difference" do
        expect([a == (set(1, 2) ^ set(2, 3))]).to have_solution(a => set(1, 3))
      end

      it "take Ruby values on the right" do
        expect([a == (set(1) | Set[2])]).to have_solution(a => set(1, 2))
        expect([a == (set(1, 2) & [2, 3])]).to have_solution(a => set(2))
        expect([a == (set(1, 2) - [*2..9])]).to have_solution(a => set(1))
      end

      it "the class methods take any number of arguments" do
        expect([a == FiniteSetExpr.Union(set(1), set(2), set(3))]).to have_solution(a => set(1, 2, 3))
        expect([a == FiniteSetExpr.Intersection(set(1, 2, 3), set(2, 3), set(3))]).to have_solution(a => set(3))
        # Difference isn't associative, so it folds left - `a - b - c`
        expect([a == FiniteSetExpr.Difference(set(1, 2, 3), set(1), set(2))]).to have_solution(a => set(3))
      end

      # ArgumentError rather than Z3::Exception, because two sorts neither of which is
      # the other is what Expr.coerce_to_same_sort reports that way
      it "refuse a set of another element sort" do
        other = FiniteSetSort.new(RealSort.new).var("other")
        expect { a | other }
          .to raise_error(ArgumentError, "Can't convert FiniteSet(Real) into FiniteSet(Int)")
        expect { a | SetSort.new(IntSort.new).var("plain_set") }
          .to raise_error(ArgumentError, "Can't convert Set(Int) into FiniteSet(Int)")
      end
    end

    describe "#add / #delete" do
      it "both give a new set, leaving the receiver alone" do
        expect([a == sort.Empty.add(3), a.include?(3)]).to have_solution({})
        expect([a == set(1, 2).delete(2), a == Set[1]]).to have_solution({})
        expect([a == set(1), a.add(2) == Set[1, 2], a == Set[1]]).to have_solution({})
      end

      it "deleting something which was never there is fine" do
        expect([a == set(1).delete(9), a == Set[1]]).to have_solution({})
      end

      it "casts into the element sort" do
        expect { a.add("nope") }.to raise_error(Z3::Exception, "Can't convert String into Int")
        expect { a.delete("nope") }.to raise_error(Z3::Exception, "Can't convert String into Int")
      end
    end

    describe "#subset? and friends" do
      it "subset and superset are not proper" do
        expect([set(1).subset?(set(1, 2))]).to have_solution({})
        expect([set(1, 2).subset?(set(1, 2))]).to have_solution({})
        expect([set(1, 2).subset?(set(1))]).to have_no_solution
        expect([set(1, 2).superset?(set(1))]).to have_solution({})
      end

      it "the proper forms exclude equality" do
        expect([set(1).proper_subset?(set(1, 2))]).to have_solution({})
        expect([set(1, 2).proper_subset?(set(1, 2))]).to have_no_solution
        expect([set(1, 2).proper_superset?(set(1))]).to have_solution({})
        expect([set(1, 2).proper_superset?(set(1, 2))]).to have_no_solution
      end

      it "the operators are Ruby's" do
        expect([set(1) <= set(1, 2)]).to have_solution({})
        expect([set(1, 2) <= set(1, 2)]).to have_solution({})
        expect([set(1, 2) < set(1, 2)]).to have_no_solution
        expect([set(1, 2) >= set(1)]).to have_solution({})
        expect([set(1, 2) > set(1)]).to have_solution({})
      end

      it "take Ruby values" do
        expect([a.subset?(Set[1, 2]), a == Set[1]]).to have_solution({})
        expect([a.superset?([1]), a == Set[1, 2]]).to have_solution({})
      end
    end

    describe "#disjoint? / #intersect?" do
      it "ask whether the intersection is empty" do
        expect([set(1).disjoint?(set(2))]).to have_solution({})
        expect([set(1).disjoint?(set(1))]).to have_no_solution
        expect([set(1, 2).intersect?(set(2, 3))]).to have_solution({})
        expect([set(1).intersect?(set(2))]).to have_no_solution
      end
    end

    # Refused outright while Z3 hangs on it - see FiniteSetExpr::MAP_HANGS and the
    # example in spec/upstream_bugs_spec.rb which pins the hang itself. When Z3 stops
    # hanging, `MAP_HANGS[:fixed_in]` gets a version and the rest of this comes back.
    describe "#map" do
      def map_refused(&block)
        expect(&block).to raise_error(Z3::Exception, /hangs on any query about set\.map/)
      end

      it "is refused, because Z3 hangs on it" do
        map_refused { a.map { |x| x * 10 } }
        map_refused { a.collect { |x| x * 10 } }
        map_refused { a.map(Z3.Lambda(Z3.Int("map_x"), Z3.Int("map_x") * 10)) }
      end

      it "is refused before the block is looked at, so a bad one raises this too" do
        map_refused { a.map }
        map_refused { a.map(3) }
      end
    end

    describe "#select" do
      # Z3 answers `:unknown` to most questions about `set.filter`, so these check the
      # term rather than the solving. It does always answer, which is what separates it
      # from #map.
      it "builds a filter over the same sort" do
        expect(set(1, 2, 3).select { |x| x > 1 }.sort).to eq(sort)
        expect(set(1, 2, 3).select { |x| x > 1 }).to be_a FiniteSetExpr
      end

      it "is also spelled #filter" do
        expect(FiniteSetExpr.instance_method(:filter)).to eq(FiniteSetExpr.instance_method(:select))
      end

      # Two block forms don't build the same term - each conjures its own fresh bound
      # variable - so this checks the lambda given is the one that ends up in the term
      it "takes a lambda instead of a block" do
        x = Z3.Int("select_lambda_x")
        predicate = Z3.Lambda(x, x > 1)
        filtered = set(1, 2).select(predicate)
        expect(filtered.arguments[0]).to eql(predicate)
        expect(filtered.arguments[1]).to eql(set(1, 2))
      end

      it "decides the cases it can" do
        expect([set(1, 2, 3).select { |x| x > 1 }.include?(1)]).to have_no_solution
        expect([fs_empty.select { |x| x > 1 }.include?(1)]).to have_no_solution
      end

      it "wants exactly one of a function and a block" do
        x = Z3.Int("select_both_x")
        expect { a.select }
          .to raise_error(Z3::Exception, "#select needs a function or a block")
        expect { a.select(Z3.Lambda(x, x > 0)) { |y| y > 0 } }
          .to raise_error(Z3::Exception, "Pass a function or a block, not both")
      end

      it "wants a function to Bool over the element sort" do
        x = Z3.Int("select_x")
        r = Z3.Real("select_r")
        expect { a.select(Z3.Lambda(x, x * 2)) }
          .to raise_error(Z3::Exception, "#select wants a function to Bool, got one to Int")
        expect { a.select(Z3.Lambda(r, r > 0)) }
          .to raise_error(Z3::Exception, "#select wants a one argument function over Int, got Set(Real)")
        expect { a.select(3) }
          .to raise_error(Z3::Exception, "#select wants a one argument function over Int, got Integer")
      end
    end

    describe "#value" do
      it "gives a Ruby Set back" do
        expect(sort.Empty.value).to eq(Set[])
        expect(set(1, 2, 3).value).to eq(Set[1, 2, 3])
        expect(sort.Range(1, 3).value).to eq(Set[1, 2, 3])
      end

      it "works out the set operations, which Z3 leaves alone" do
        expect((set(1, 2) | set(2, 3)).value).to eq(Set[1, 2, 3])
        expect((set(1, 2) & set(2, 3)).value).to eq(Set[2])
        expect((set(1, 2) - set(2)).value).to eq(Set[1])
        expect(set(1, 2).add(9).delete(1).value).to eq(Set[2, 9])
      end

      it "nests" do
        expect(nested.from_const([Set[1, 2], Set[3]]).value).to eq(Set[Set[1, 2], Set[3]])
      end

      it "comes back out of a model" do
        solver = Solver.new
        solver.assert a == Set[3, 5]
        expect(solver.check).to eq(:sat)
        expect(solver.model[a].value).to eq(Set[3, 5])
      end

      it "refuses an expression which isn't a set value" do
        expect { a.value }
          .to raise_error(Z3::Exception, "Can't convert expression a into Set")
        expect { (a | set(1)).value }
          .to raise_error(Z3::Exception, /Can't convert expression .* into Set/)
        expect { set(1, 2).select { |x| x > 1 }.value }
          .to raise_error(Z3::Exception, /Can't convert expression .* into Set/)
      end

      # Z3 writes a set it only had to decide the size of as `set.unique`, which is
      # not a set Ruby has - the same shape as SetExpr#value refusing a co-finite set
      it "refuses a set whose elements the solver never pinned down" do
        solver = Solver.new
        solver.assert a.size == 2
        expect(solver.check).to eq(:sat)
        expect { solver.model[a].value }.to raise_error(
          Z3::Exception,
          /the solver settled how many elements it has without deciding which/,
        )
      end
    end

    describe "printing" do
      it "prints set values as Ruby Set literals" do
        expect(sort.Empty).to stringify("Set[]")
        expect(set(1)).to stringify("Set[1]")
        expect(set(1, 2, 3)).to stringify("Set[1, 2, 3]")
        expect(sort.Range(1, 3)).to stringify("(1..3)")
      end

      it "prints the operations the way they're written" do
        expect(a.size).to stringify("a.size")
        expect(a.include?(3)).to stringify("a.include?(3)")
        expect(a.subset?(b)).to stringify("a.subset?(b)")
        expect(a | b).to stringify("a | b")
        expect(a & b).to stringify("a & b")
        expect(a - b).to stringify("a - b")
      end

      it "merges runs of singletons into one literal, leaving the rest" do
        expect(a | set(1, 2)).to stringify("a | Set[1, 2]")
        expect(set(1) | a | set(2)).to stringify("Set[1] | a | Set[2]")
      end

      it "parenthesises where it has to" do
        expect((a | b).size).to stringify("(a | b).size")
        expect(a - (b - a)).to stringify("a - (b - a)")
      end
    end
  end
end
