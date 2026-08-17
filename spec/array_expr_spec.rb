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

    describe "#value" do
      it "gives a Ruby Hash back, with the array's default as the Hash default" do
        hash = sort.Const(0).store(2, 7).value
        expect(hash).to eq({2 => 7})
        expect(hash[2]).to eq(7)
        # An array is a total map, so the entries alone can't say what it is
        expect(hash[5]).to eq(0)
        expect(sort.Const(3).value).to eq({})
        expect(sort.Const(3).value[5]).to eq(3)
      end

      it "applies the stores in order, so a later one to the same key wins" do
        expect(sort.Const(0).store(1, 5).store(1, 7).value).to eq({1 => 7})
        expect(sort.Const(0).store(1, 5).store(2, 7).value).to eq({1 => 5, 2 => 7})
      end

      # It reads the term as it stands rather than canonicalising it
      it "keeps a store of the default value as an entry" do
        expect(sort.Const(0).store(1, 0).value).to eq({1 => 0})
      end

      it "simplifies first, like every other #value" do
        ite = Z3.IfThenElse(BoolSort.new.True, sort.Const(0), sort.Const(1))
        expect(ite.value).to eq({})
        expect(ite.value[5]).to eq(0)
      end

      it "calls #value on keys and values" do
        strings = ArraySort.new(StringSort.new, IntSort.new)
        expect(strings.Const(0).store("a", 1).value).to eq({"a" => 1})
      end

      it "raises exception when there's nothing to convert" do
        expect { a.value }.to raise_error(Z3::Exception)
        expect { a.store(1, 2).value }.to raise_error(Z3::Exception)
        # A lambda is a perfectly good array value, and no finite Hash
        expect { Z3.Lambda(x, x * 2).value }.to raise_error(Z3::Exception)
      end

      it "reads a model" do
        solver = Solver.new
        solver.assert a[1] == 10
        solver.assert a[2] == 20
        expect(solver).to be_satisfiable
        hash = solver.model[a].value
        expect(hash[1]).to eq(10)
        expect(hash[2]).to eq(20)
      end
    end

    it "== and !=" do
      expect([a == b, b != c]).to have_solution(
        a => sort.Const(0).store(0, 1),
        b => sort.Const(0).store(0, 1),
        c => sort.Const(0),
      )
    end

    it "reading with []" do
      expect([a[10] == 20]).to have_solution(
        a => sort.Const(20),
      )
      # Forced x and y to specific values, otherwise this spec fails between versions
      expect([a[x] == 10, a[y] == 20, x == 30, y == 40]).to have_solution(
        a => sort.Const(20).store(30, 10),
        #    sort.Const(10).store(40, 20) would also work
        x => 30,
        y => 40,
      )
    end

    it "store" do
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
