module Z3
  describe ArrayExpr do
    let(:sort) { ArraySort.new(IntSort.new, IntSort.new) }
    let(:a) { sort.var("a") }
    let(:b) { sort.var("b") }
    let(:c) { sort.var("c") }
    let(:x) { Z3::Int("x") }
    let(:y) { Z3::Int("y") }
    let(:z) { Z3::Int("z") }

    describe "#default" do
      it "is what a Const array answers everywhere" do
        expect([sort.Const(0).default != 0]).to have_no_solution
      end

      # It's the fallback, not the value everywhere - #store doesn't touch it
      it "survives a store" do
        expect([sort.Const(0).store(7, 1).default != 0]).to have_no_solution
        expect([sort.Const(0).store(7, 1)[7] != 1]).to have_no_solution
      end

      # The default is the fallback, so it says nothing about keys which were written.
      # Only assertable, not readable - Z3 solves with it but won't reduce
      # `default(store(const(9), 0, 1))` to a numeral, in a model or under #simplify.
      it "can be constrained on a free array" do
        solver = Solver.new
        solver.assert a.default == 9
        solver.assert a[0] == 1
        solver.assert a[1] == 2
        expect(solver).to be_satisfiable

        expect([a.default == 9, a.default == 8]).to have_no_solution
      end

      it "has the array's value sort" do
        expect(a.default.sort).to eq(IntSort.new)
        expect(ArraySort.new(IntSort.new, BoolSort.new).var("d").default.sort).to eq(BoolSort.new)
      end
    end

    # TODO: Formatting is dreadful
    it "== and !=" do
      expect([a == b, b != c]).to have_solution(
        a => "store(const(0), 0, 1)",
        b => "store(const(0), 0, 1)",
        c => "const(0)",
      )
    end

    it "select" do
      expect([a.select(10) == 20]).to have_solution(
        a => "const(20)",
      )
      expect([a[10] == 20]).to have_solution(
        a => "const(20)",
      )
      # Forced x and y to specific values, otherwise this spec fails between versions
      expect([a[x] == 10, a[y] == 20, x == 30, y == 40]).to have_solution(
        a => "store(const(20), 30, 10)",
        #    "store(const(10), 40, 20)" would also work
        x => "30",
        y => "40",
      )
    end

    it "store" do
      expect([a == b.store(10, 20), x == a.select(10)]).to have_solution(
        x => 20,
      )
      expect([a == b.store(10, 20), x == a[10]]).to have_solution(
        x => 20,
      )
      expect([a == b.store(10, 20), x == a[y], y == 10]).to have_solution(
        x => 20,
      )
      # `b` is a free array, so `x == 20` alone doesn't say where the 20 came from -
      # Z3 is free to answer `b = store(const(2), 3, 20), y = 3`, and which way it
      # goes depends on what else has been solved in the process already.
      # `b[y] != 20` rules out every index the store didn't write, forcing y == 10.
      expect([a == b.store(10, 20), x == a[y], x == 20, b[y] != 20]).to have_solution(
        x => 20,
        y => 10,
      )
    end
  end
end
