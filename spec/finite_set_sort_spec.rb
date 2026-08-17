module Z3
  describe FiniteSetSort do
    before { skip "Finite sets were added in Z3 5.0" unless Z3.version_at_least?(5, 0) }

    let(:sort)        { FiniteSetSort.new(IntSort.new) }
    let(:bool_set)    { FiniteSetSort.new(BoolSort.new) }
    let(:string_set)  { FiniteSetSort.new(StringSort.new) }
    let(:nested)      { FiniteSetSort.new(FiniteSetSort.new(IntSort.new)) }

    it "to_s and inspect" do
      expect(sort.to_s).to eq("FiniteSet(Int)")
      expect(sort.inspect).to eq("FiniteSetSort(Int)")
      expect(nested.to_s).to eq("FiniteSet(FiniteSet(Int))")
    end

    it "is a value object" do
      expect(sort).to eq(FiniteSetSort.new(IntSort.new))
      expect(sort).to_not eq(FiniteSetSort.new(RealSort.new))
    end

    # A FiniteSet(X) and a Set(X) are different Z3 sorts, unlike Set(X) and
    # Array(X, Bool), which are the same one under two Ruby classes
    it "is not the same sort as SetSort" do
      expect(sort).to_not eq(SetSort.new(IntSort.new))
      expect(sort.element_sort).to eq(IntSort.new)
    end

    it "can instantiate variables" do
      expect(sort.var("a").inspect).to eq("FiniteSet(Int)<a>")
      expect(bool_set.var("a").inspect).to eq("FiniteSet(Bool)<a>")
      expect(nested.var("a").inspect).to eq("FiniteSet(FiniteSet(Int))<a>")
    end

    it "needs a sort to be over" do
      expect { FiniteSetSort.new(42) }
        .to raise_error(Z3::Exception, "Sort expected, got Integer")
    end

    describe "#Empty and #Singleton" do
      it "builds them" do
        expect(sort.Empty.value).to eq(Set[])
        expect(sort.Singleton(3).value).to eq(Set[3])
      end

      it "they have the sort they claim to have" do
        expect(sort.Empty.sexpr).to eq("(as set.empty (FiniteSet Int))")
        expect(sort.Empty.sort).to eq(sort)
        expect(sort.Singleton(3).sort).to eq(sort)
      end

      it "casts Ruby values into the element sort" do
        expect(string_set.Singleton("hi").value).to eq(Set["hi"])
        expect { sort.Singleton("nope") }
          .to raise_error(Z3::Exception, "Can't convert String into Int")
      end
    end

    describe "#Range" do
      it "is every Integer between the ends, both included" do
        expect(sort.Range(1, 4).value).to eq(Set[1, 2, 3, 4])
        expect(sort.Range(3, 3).value).to eq(Set[3])
      end

      # The one place a Ruby Range is accepted, and only as a pair of ends - it is not
      # a set value anywhere, since `Set[1, 2, 3] != (1..3)` in Ruby either
      it "takes one Ruby Range instead of two ends" do
        expect(sort.Range(1..4)).to eql(sort.Range(1, 4))
        expect(sort.Range(1...4)).to eql(sort.Range(1, 3))
      end

      it "refuses a Range which doesn't end, and anything which isn't one" do
        expect { sort.Range(1..) }.to raise_error(
          Z3::Exception, "FiniteSet(Int)#Range needs a Range with both ends, got 1..",
        )
        expect { sort.Range(3) }.to raise_error(
          Z3::Exception, "FiniteSet(Int)#Range takes two ends or one Range, got Integer",
        )
      end

      # Asked about membership. Deliberately not asked with `==`, which Z3 5.0 gets
      # wrong once an end is symbolic - see spec/upstream_bugs_spec.rb
      it "takes symbolic ends, which is the point of it" do
        n = Z3.Int("n")
        expect([sort.Range(1, n).include?(3), n == 5]).to have_solution({})
        expect([sort.Range(1, n).include?(3), n == 2]).to have_no_solution
        expect([sort.Range(n, 10).include?(3), n == 7]).to have_no_solution
      end

      # Z3's own message is "Sort mismatch for function 'set.range'", which doesn't
      # say which sort was wrong or that Int was wanted
      it "is Ints only" do
        expect { string_set.Range("a", "z") }.to raise_error(
          Z3::Exception,
          "Only FiniteSet(Int) has ranges, FiniteSet(String) has no order to take one along",
        )
      end
    end

    describe "#from_const" do
      it "takes a Set or an Array, which mean the same thing" do
        expect(sort.from_const(Set[1, 2, 3]).value).to eq(Set[1, 2, 3])
        expect(sort.from_const([1, 2, 3]).value).to eq(Set[1, 2, 3])
      end

      it "drops duplicates, since a Set has none to keep" do
        expect(sort.from_const([1, 1, 2]).value).to eq(Set[1, 2])
        # `eql?`, not `==` - `==` on two Exprs builds an equation rather than answering
        expect(sort.from_const([1, 1, 2])).to eql(sort.from_const(Set[1, 2]))
      end

      it "takes an empty one" do
        expect(sort.from_const(Set[]).value).to eq(Set[])
        expect(sort.from_const([]).value).to eq(Set[])
      end

      it "casts elements into the element sort" do
        expect(bool_set.from_const([true, false]).value).to eq(Set[true, false])
        expect { sort.from_const(["nope"]) }
          .to raise_error(Z3::Exception, "Can't convert String into Int")
      end

      it "nests" do
        expect(nested.from_const([Set[1, 2], Set[3]]).value).to eq(Set[Set[1, 2], Set[3]])
      end

      it "refuses anything which isn't a set" do
        expect { sort.from_const(3) }
          .to raise_error(Z3::Exception, "Can't convert Integer into FiniteSet(Int)")
        expect { sort.from_const(nil) }
          .to raise_error(Z3::Exception, "Can't convert nil into FiniteSet(Int)")
      end

      # A Range is a pair of ends for #Range and nothing else - `[*1..3]` is how you
      # write one as a set
      it "refuses a Range, which is not a set value" do
        expect { sort.from_const(1..3) }
          .to raise_error(Z3::Exception, "Can't convert Range into FiniteSet(Int)")
        expect(sort.from_const([*1..3]).value).to eq(Set[1, 2, 3])
      end
    end

    # The sort has no `Z3_sort_kind` of its own, so `Sort.from_pointer` has to
    # recognise it by predicate - see spec/upstream_bugs_spec.rb
    it "comes back out of a model as itself" do
      a = sort.var("a")
      solver = Solver.new
      solver.assert a == Set[1, 2]
      expect(solver.check).to eq(:sat)
      expect(solver.model[a].sort).to eq(sort)
      expect(solver.model[a]).to be_a FiniteSetExpr
    end

    it "comes back out of a nested model as itself" do
      a = nested.var("a")
      solver = Solver.new
      solver.assert a == Set[Set[1], Set[2]]
      expect(solver.check).to eq(:sat)
      expect(solver.model[a].sort).to eq(nested)
      expect(solver.model[a].value).to eq(Set[Set[1], Set[2]])
    end
  end
end
