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
      # This depends on Z3 version so it's not a great test
      expect(stats.keys).to be_an(Array)
      expect(stats.keys).to include("rlimit count", "max memory", "memory", "num allocs")
    end

    it "#assert_and_track and #unsat_core" do
      solver.assert_and_track a > 5, Z3.Bool("p1")
      solver.assert_and_track a < 2, Z3.Bool("p2")
      solver.assert_and_track b == 0, Z3.Bool("p3")
      expect(solver).to be_unsatisfiable
      # Z3 picks the order, and p3 is not part of the contradiction
      expect(solver.unsat_core.map(&:to_s).sort).to eq(["p1", "p2"])
    end

    it "#unsat_core is empty unless the solver got to blame something" do
      solver.assert_and_track a > 5, Z3.Bool("p1")
      expect(solver).to be_satisfiable
      expect(solver.unsat_core).to eq([])
    end

    it "#unsat_core only blames tracked assertions" do
      solver.assert a > 5
      solver.assert_and_track a < 2, Z3.Bool("p1")
      expect(solver).to be_unsatisfiable
      expect(solver.unsat_core.map(&:to_s)).to eq(["p1"])
    end

    it "#num_scopes" do
      expect(solver.num_scopes).to eq(0)
      solver.push
      solver.push
      expect(solver.num_scopes).to eq(2)
      solver.pop
      expect(solver.num_scopes).to eq(1)
    end

    it "#reason_unknown" do
      solver.assert a**a == a
      expect(solver.check).to eq(:unknown)
      expect(solver.reason_unknown).to include("incomplete")
    end

    it "#to_s" do
      solver.assert a + b == 4
      solver.assert b >= 2
      # Z3 picks the order it declares consts in, so only the parts we control are checked
      expect(solver.to_s).to include("(declare-fun a () Int)")
      expect(solver.to_s).to include("(declare-fun b () Int)")
      expect(solver.to_s).to include("(assert (= (+ a b) 4))")
      expect(solver.to_s).to include("(assert (>= b 2))")
    end

    it "#to_dimacs" do
      solver.assert Z3.Or(Z3.Bool("p"), Z3.Bool("q"))
      # Z3 emits the name comments in whatever order it happens to iterate in
      expect(solver.to_dimacs.lines.map(&:chomp).sort).to eq(["1 2 0", "c 1 p", "c 2 q", "p cnf 2 1"])
      expect(solver.to_dimacs(false)).to eq("p cnf 2 1\n1 2 0\n")
    end

    it "#help" do
      # This depends on Z3 version so it's not a great test
      expect(solver.help).to include("random_seed")
    end

    it "#param_descrs" do
      expect(solver.param_descrs).to include("timeout", "rlimit")
    end

    describe "parameters" do
      # `rlimit` is a deterministic resource limit, unlike `timeout`, so these
      # give the same answer no matter how fast the machine running them is.
      # rlimit of 1 is small enough that even a trivial problem runs out of budget.
      let(:easy_problem) { (a > 1) & (b > 0) & (a + b == 100) & (a * b > 300) }

      it "solver without parameters solves it" do
        solver.assert easy_problem
        expect(solver.check).to eq(:sat)
      end

      it "#set_params" do
        solver.set_params(rlimit: 1)
        solver.assert easy_problem
        expect(solver.check).to eq(:unknown)
      end

      it "#set_params returns the solver, so it chains" do
        expect(solver.set_params(rlimit: 1)).to equal(solver)
      end

      it ".new takes parameters" do
        solver = Solver.new(rlimit: 1)
        solver.assert easy_problem
        expect(solver.check).to eq(:unknown)
      end

      it "#set_params accepts a Params object" do
        solver.set_params(Params.new(rlimit: 1))
        solver.assert easy_problem
        expect(solver.check).to eq(:unknown)
      end

      it ".new accepts a Params object" do
        solver = Solver.new(Params.new(rlimit: 1))
        solver.assert easy_problem
        expect(solver.check).to eq(:unknown)
      end

      it "#set_params merges into parameters set before" do
        solver.set_params(rlimit: 1)
        solver.set_params(random_seed: 42)
        solver.assert easy_problem
        expect(solver.check).to eq(:unknown)
      end

      it "#set_params overrides parameters set before" do
        solver.set_params(rlimit: 1)
        solver.set_params(rlimit: 0) # 0 means no limit
        solver.assert easy_problem
        expect(solver.check).to eq(:sat)
      end

      # Z3 only notices bad parameters once it starts solving, and then it just
      # says Z3_EXCEPTION, so it's a lot friendlier to catch them here
      it "#set_params rejects unknown parameters" do
        expect{ solver.set_params(timout: 1000) }
          .to raise_error(Z3::Exception, "Unknown parameter `timout'")
      end

      it "#set_params rejects parameters of wrong type" do
        expect{ solver.set_params(timeout: "1000") }
          .to raise_error(Z3::Exception, "Parameter `timeout' expects uint, got \"1000\"")
      end
    end

    # This is a very simple example of unknown satisfiablity
    # so we might need more complex one in the future
    # This is now satisfiable in 4.6.0
    if Z3.version_at_least?(4, 6)
      it "unknown satisfiability (until 4.6 fix)" do
        solver.assert a**3 == a
        expect(solver.check).to eq(:sat)
        expect(solver).to be_satisfiable
        expect(solver).to_not be_unsatisfiable
      end
    else
      it "unknown satisfiability (until 4.6 fix)" do
        solver.assert a**3 == a
        expect(solver.check).to eq(:unknown)
        expect{solver.satisfiable?}.to raise_error("Satisfiability unknown")
        expect{solver.unsatisfiable?}.to raise_error("Satisfiability unknown")
      end
    end

    it "unknown satisfiability" do
      solver.assert a**a == a
      expect(solver.check).to eq(:unknown)
      expect{solver.satisfiable?}.to raise_error("Satisfiability unknown")
      expect{solver.unsatisfiable?}.to raise_error("Satisfiability unknown")
    end
  end
end
