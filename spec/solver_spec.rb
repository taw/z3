# Solver and Model specs are codependent, so half of functionality of each is tested in other class's tests
module Z3
  describe Solver do
    let(:solver) { Solver.new }
    let(:a) { Z3.Int("a") }
    let(:b) { Z3.Int("b") }

    it "basic functionality" do
      solver.assert(a == b)
      expect(solver).to be_satisfiable
      solver.assert(a != b)
      expect(solver).to be_unsatisfiable
    end

    it "push/pop" do
      solver.assert(a == b)
      solver.push
      solver.assert(a != b)
      expect(solver).to be_unsatisfiable
      solver.pop
      expect(solver).to be_satisfiable
    end

    it "#assertions" do
      solver.assert a + b == 4
      solver.assert b >= 2
      solver.assert Z3.Or(a == 2, a == -2)
      expect(solver.assertions).to be_same_as([
        a + b == 4,
        b >= 2,
        (a == 2) | (a == -2),
      ])
    end

    it "#statistics" do
      solver.assert a + b == 4
      solver.assert b >= 2
      solver.assert Z3.Or(a == 2, a == -2)
      stats = solver.statistics
      expect(stats.keys).to match_array(["rlimit count", "max memory", "memory", "num allocs"])
    end

    # This is a very simple example of unknown satisfiablity
    # so we might need more complex one in the future
    it "third way" do
      solver.assert a**3 == a
      expect(solver.check).to eq(:unknown)
      expect{solver.satisfiable?}.to raise_error("Satisfiability unknown")
      expect{solver.unsatisfiable?}.to raise_error("Satisfiability unknown")
    end
  end
end
