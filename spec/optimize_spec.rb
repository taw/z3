# Optimize and Model specs are codependent, so half of functionality of each is tested in other class's tests
module Z3
  describe Optimize do
    let(:optimize) { Optimize.new }
    let(:a) { Z3.Int("a") }
    let(:b) { Z3.Int("b") }

    it "basic functionality" do
      optimize.assert(a == b)
      expect(optimize).to be_satisfiable
      optimize.assert(a != b)
      expect(optimize).to be_unsatisfiable
    end

    it "push/pop" do
      optimize.assert(a == b)
      optimize.push
      optimize.assert(a != b)
      expect(optimize).to be_unsatisfiable
      optimize.pop
      expect(optimize).to be_satisfiable
    end

    it "#assertions" do
      optimize.assert a + b == 4
      optimize.assert b >= 2
      optimize.assert Z3.Or(a == 2, a == -2)
      expect(optimize.assertions).to be_same_as([
        a + b == 4,
        b >= 2,
        (a == 2) | (a == -2),
      ])
    end

    it "#statistics" do
      optimize.assert a + b == 4
      optimize.assert b >= 2
      optimize.assert Z3.Or(a == 2, a == -2)
      stats = optimize.statistics
      expect(stats.keys).to match_array(["rlimit count", "max memory", "memory", "num allocs"])
    end

    # This is a very simple example of unknown satisfiablity
    # so we might need more complex one in the future
    # Unlike Z3::Solver, this is unknown even 4.6.0
    it "third way" do
      optimize.assert a**3 == a
      expect(optimize.check).to eq(:unknown)
      expect{optimize.satisfiable?}.to raise_error("Satisfiability unknown")
      expect{optimize.unsatisfiable?}.to raise_error("Satisfiability unknown")
    end

    it "third way" do
      optimize.assert a**a == a
      expect(optimize.check).to eq(:unknown)
      expect{optimize.satisfiable?}.to raise_error("Satisfiability unknown")
      expect{optimize.unsatisfiable?}.to raise_error("Satisfiability unknown")
    end

    it "maximize" do
      optimize.assert a > 0
      optimize.assert a < 10
      optimize.maximize a
      expect(optimize).to be_satisfiable
      expect(optimize.model[a].to_i).to eq 9
    end

    it "maximize" do
      optimize.assert a > 0
      optimize.assert a < 10
      optimize.minimize a
      expect(optimize).to be_satisfiable
      expect(optimize.model[a].to_i).to eq 1
    end
  end
end
