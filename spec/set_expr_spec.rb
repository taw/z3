# This test is really bad, all of these have multiple solutions.
# And it changes between Z3 versions
module Z3
  describe SetExpr do
    let(:sort) { SetSort.new(IntSort.new) }
    let(:a) { sort.var("a") }
    let(:b) { sort.var("b") }
    let(:c) { sort.var("c") }
    let(:x) { Z3::Bool("x") }

    # Both give a new set, the way #union does - no Z3 expression is mutable, so
    # unlike Ruby's Set#add the receiver is left alone
    describe "#add / #delete" do
      it "add puts an element in" do
        expect([sort.Empty.add(3).include?(3)]).to have_solution({})
        expect([~sort.Empty.add(3).include?(4)]).to have_solution({})
        expect([~sort.Empty.add(3).include?(3)]).to have_no_solution
      end

      it "delete takes one out" do
        expect([~sort.Full.delete(3).include?(3)]).to have_solution({})
        expect([sort.Full.delete(3).include?(4)]).to have_solution({})
        expect([sort.Full.delete(3).include?(3)]).to have_no_solution
      end

      it "leaves the set it was called on alone" do
        expect([a == sort.Empty, a.add(3).include?(3), ~a.include?(3)]).to have_solution({})
      end

      it "deleting something which was never there is fine" do
        expect([~sort.Empty.delete(3).include?(3)]).to have_solution({})
      end

      it "casts Ruby values into the element sort" do
        expect(sort.Empty.add(3)).to be_a SetExpr
        expect{ sort.Empty.add("nope") }
          .to raise_error(Z3::Exception, "Can't convert String into Int")
        expect{ sort.Empty.delete("nope") }
          .to raise_error(Z3::Exception, "Can't convert String into Int")
      end
    end

    describe "#value" do
      it "gives a Ruby Set back" do
        expect(sort.Empty.value).to eq(Set[])
        expect(sort.Empty.add(3).add(5).value).to eq(Set[3, 5])
        expect(sort.Empty.add(3).delete(3).value).to eq(Set[])
      end

      it "simplifies first, like every other #value" do
        expect(sort.Empty.add(3).add(3).value).to eq(Set[3])
        expect(Z3.IfThenElse(BoolSort.new.True, sort.Empty.add(3), sort.Empty).value).to eq(Set[3])
      end

      # Z3's simplifier leaves most of these as a `map(or, ...)` - `f` applied pointwise
      # to the arrays underneath - rather than working the elements out, and models hold
      # them in that form too
      it "works out a set operation Z3 left as a pointwise map" do
        expect(sort.Empty.add(3).union(sort.Empty.add(5)).value).to eq(Set[3, 5])
        expect(sort.Empty.add(3).add(5).difference(sort.Empty.add(5)).value).to eq(Set[3])
        expect(sort.Empty.add(3).add(5).intersection(sort.Empty.add(5)).value).to eq(Set[5])

        solver = Solver.new
        solver.assert a == sort.Empty.add(3).union(sort.Empty.add(5))
        expect(solver).to be_satisfiable
        expect(solver.model[a].to_s).to include("map")
        expect(solver.model[a].value).to eq(Set[3, 5])
      end

      # A union with a co-finite set is co-finite, and that's still no Ruby Set
      it "raises on a map which comes out co-finite" do
        expect { sort.Empty.add(3).union(sort.Full).value }.to raise_error(Z3::Exception)
      end

      it "calls #value on the elements" do
        expect(SetSort.new(StringSort.new).Empty.add("a").value).to eq(Set["a"])
      end

      # A Z3 set is an Array to Bool, so it's just as happy holding everything except a
      # few elements. Ruby has no co-finite set, so that raises instead of lying, and
      # #complement is how you ask which elements it leaves out.
      it "raises on a co-finite set, and #complement is the way round it" do
        expect { sort.Full.value }.to raise_error(Z3::Exception)
        expect { sort.Full.delete(3).value }.to raise_error(Z3::Exception)
        expect(sort.Full.delete(3).complement.value).to eq(Set[3])
      end

      it "raises exception when there's nothing to convert" do
        expect { a.value }.to raise_error(Z3::Exception)
        expect { a.add(3).value }.to raise_error(Z3::Exception)
      end

      it "reads a model" do
        solver = Solver.new
        solver.assert a == sort.Empty.add(4).add(6)
        expect(solver).to be_satisfiable
        expect(solver.model[a].value).to eq(Set[4, 6])
      end

      # A model is where co-finite sets actually turn up: asked for no more than
      # "3 is in it, 5 isn't", the solver quite reasonably answers "everything except 5"
      it "reads a model of a co-finite set through #complement" do
        solver = Solver.new
        solver.assert a == sort.Full.delete(5)
        expect(solver).to be_satisfiable
        expect { solver.model[a].value }.to raise_error(Z3::Exception)
        expect(solver.model[a].complement.value).to eq(Set[5])
      end
    end

    it "== and !=" do
      expect([a == b, b != c]).to have_solution(
        a => sort.Empty.add(0),
        b => sort.Empty.add(0),
        c => sort.Empty,
      )
    end

    it "union" do
      expect([
        a.include?(1),
        a.include?(2),
        !a.include?(3),
        !b.include?(1),
        b.include?(2),
        b.include?(3),
        c == a.union(b),
      ]).to have_solution(
        a => sort.Full.delete(3),
        b => sort.Full.delete(1),
        c => sort.Full,
      )
    end

    it "difference" do
      expect([
        a.include?(1),
        a.include?(2),
        !a.include?(3),
        !b.include?(1),
        b.include?(2),
        b.include?(3),
        c == a.difference(b),
      ]).to have_solution(
        a => sort.Full.delete(3),
        b => sort.Full.delete(1),
        # a & !b
        c => sort.Empty.add(1),
      )
    end

    it "intersection" do
      expect([
        a.include?(1),
        a.include?(2),
        !a.include?(3),
        !b.include?(1),
        b.include?(2),
        b.include?(3),
        c == a.intersection(b),
      ]).to have_solution(
        a => sort.Full.delete(3),
        b => sort.Full.delete(1),
        c => sort.Full.delete(1).delete(3),
      )
    end
  end
end
