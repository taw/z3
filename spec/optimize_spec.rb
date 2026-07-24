# Optimize and Model specs are codependent, so half of functionality of each is tested in other class's tests

# Disabled as it crashes on Z3 4.8.13
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

    it "#assert_soft" do
      optimize.assert_soft a > 0
      optimize.assert_soft a < 0
      optimize.assert_soft a < 10
      optimize.maximize a
      expect(optimize).to be_satisfiable
      expect(optimize.model[a].to_i).to eq 9
    end

    it "#statistics" do
      optimize.assert a + b == 4
      optimize.assert b >= 2
      optimize.assert Z3.Or(a == 2, a == -2)
      stats = optimize.statistics
      expect(stats.keys).to match_array(["rlimit count", "max memory", "memory", "num allocs"])
    end

    it "unknown satisfiability" do
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

    it "minimize" do
      optimize.assert a > 0
      optimize.assert a < 10
      optimize.minimize a
      expect(optimize).to be_satisfiable
      expect(optimize.model[a].to_i).to eq 1
    end

    it "maximize invalidates the model" do
      optimize.assert a > 0
      optimize.assert a < 10
      expect(optimize).to be_satisfiable
      expect(optimize.model[a].to_i).to be_between(1, 9)
      optimize.maximize a
      expect{optimize.model}.to raise_error("You need to check that it's satisfiable before asking for the model")
      expect(optimize).to be_satisfiable
      expect(optimize.model[a].to_i).to eq 9
    end

    it "minimize invalidates the model" do
      optimize.assert a > 0
      optimize.assert a < 10
      expect(optimize).to be_satisfiable
      expect(optimize.model[a].to_i).to be_between(1, 9)
      optimize.minimize a
      expect{optimize.model}.to raise_error("You need to check that it's satisfiable before asking for the model")
      expect(optimize).to be_satisfiable
      expect(optimize.model[a].to_i).to eq 1
    end

    it "#assert_and_track and #unsat_core" do
      optimize.assert_and_track a > 5, Z3.Bool("p1")
      optimize.assert_and_track a < 2, Z3.Bool("p2")
      expect(optimize).to be_unsatisfiable
      expect(optimize.unsat_core.map(&:to_s).sort).to eq(["p1", "p2"])
    end

    it "#to_s" do
      optimize.assert a > 3
      expect(optimize.to_s).to include("(declare-fun a () Int)")
      expect(optimize.to_s).to include("(assert (> a 3))")
    end

    it "#help" do
      # This depends on Z3 version so it's not a great test
      expect(optimize.help).to include("timeout")
    end

    it "#param_descrs" do
      expect(optimize.param_descrs).to include("timeout", "rlimit")
    end

    describe "parameters" do
      # See solver_spec for why this uses `rlimit` rather than `timeout`
      let(:easy_problem) { (a > 1) & (b > 0) & (a + b == 100) & (a * b > 300) }

      it "optimize without parameters solves it" do
        optimize.assert easy_problem
        expect(optimize.check).to eq(:sat)
      end

      it "#set_params" do
        optimize.set_params(rlimit: 1)
        optimize.assert easy_problem
        expect(optimize.check).to eq(:unknown)
      end

      it ".new takes parameters" do
        optimize = Optimize.new(rlimit: 1)
        optimize.assert easy_problem
        expect(optimize.check).to eq(:unknown)
      end

      # Optimize takes far fewer parameters than Solver, and this is one Solver has
      it "#set_params rejects parameters Optimize does not take" do
        expect{ optimize.set_params("arith.nl" => true) }
          .to raise_error(Z3::Exception, "Unknown parameter `arith.nl'")
      end
    end
  end
end
