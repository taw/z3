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

    # TODO: Formatting is dreadful
    it "== and !=" do
      expect([a == b, b != c]).to have_solution(
        a => "store(const(false), 0, true)",
        b => "store(const(false), 0, true)",
        c => "const(false)",
      )
    end

    if Z3.version_at_least?(4, 5)
      # Only works in z3 4.5, 4.4 (like on Ubuntu) returns bad stuff
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
          a => "store(const(true), 3, false)",
          b => "store(const(true), 1, false)",
          c => "map(or, store(const(true), 3, false), store(const(true), 1, false))",
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
          a => "store(const(true), 3, false)",
          b => "store(const(true), 1, false)",
          # a & !b
          c => "map(and, store(const(true), 3, false), store(const(false), 1, true))",
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
          a => "store(const(true), 3, false)",
          b => "store(const(true), 1, false)",
          c => "map(and, store(const(true), 3, false), store(const(true), 1, false))",
        )
      end
    end
  end
end
