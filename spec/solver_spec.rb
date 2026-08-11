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

    describe "#check with assumptions" do
      let(:p) { Z3.Bool("p") }
      let(:q) { Z3.Bool("q") }

      it "solves under the assumptions" do
        solver.assert p.implies(a == 1)
        solver.assert q.implies(a == 2)
        expect(solver.check(p)).to eq(:sat)
        expect(solver.model[a].to_s).to eq("1")
        expect(solver.check(q)).to eq(:sat)
        expect(solver.model[a].to_s).to eq("2")
        expect(solver.check(p, q)).to eq(:unsat)
      end

      it "leaves no trace on the solver" do
        solver.assert p.implies(a == 1)
        expect(solver.check(p, a == 2)).to eq(:unsat)
        # Neither the assumptions nor a scope to pop them off in
        expect(solver.check).to eq(:sat)
        expect(solver.assertions).to be_same_as([p.implies(a == 1)])
        expect(solver.num_scopes).to eq(0)
      end

      it "assumptions are what #unsat_core blames" do
        solver.assert p.implies(a > 5)
        solver.assert q.implies(a < 2)
        expect(solver.check(p, q, a == 3)).to eq(:unsat)
        # Z3 picks the order, and `a == 3` is not part of the contradiction
        expect(solver.unsat_core.map(&:to_s).sort).to eq(["p", "q"])
      end

      it "no assumptions is the same as no arguments at all" do
        solver.assert a == 1
        expect(solver.check(*[])).to eq(:sat)
        expect(solver.model[a].to_s).to eq("1")
      end

      it "#satisfiable? and #unsatisfiable? pass assumptions through" do
        solver.assert p.implies(a == 1)
        expect(solver.satisfiable?(p)).to eq(true)
        expect(solver.unsatisfiable?(p, a == 2)).to eq(true)
      end

      it "takes true and false" do
        solver.assert a == 1
        expect(solver.check(true)).to eq(:sat)
        expect(solver.check(false)).to eq(:unsat)
      end

      it "raises on assumptions which aren't Bool" do
        expect{ solver.check(a) }.to raise_error(Z3::Exception, "Can't convert Int into Bool")
        expect{ solver.check(42) }.to raise_error(Z3::Exception, "Can't convert Integer into Bool")
      end

      # The C API documents assumptions as propositional literals, but Z3 takes any
      # Bool formula and puts it in the unsat core verbatim
      it "takes assumptions which aren't literals" do
        solver.assert a > 0
        expect(solver.check(p | q, a < 0)).to eq(:unsat)
        expect(solver.unsat_core.map(&:to_s)).to eq(["a < 0"])
      end
    end

    describe "#consequences" do
      let(:p) { Z3.Bool("p") }
      let(:q) { Z3.Bool("q") }
      let(:r) { Z3.Bool("r") }

      it "reports what follows from the assertions" do
        solver.assert Z3.Implies(p, q)
        solver.assert Z3.Implies(q, r)
        solver.assert p
        expect(solver.consequences([p, q, r]).map(&:to_s).sort)
          .to eq(["true => p", "true => q", "true => r"])
      end

      it "reports what follows only under an assumption" do
        solver.assert Z3.Implies(p, q)
        expect(solver.consequences([q], [p]).map(&:to_s)).to eq(["p => q"])
        expect(solver.consequences([q])).to eq([])
      end

      it "raises unless the assertions are satisfiable" do
        solver.assert p
        solver.assert ~p
        expect{ solver.consequences([p]) }.to raise_error(Z3::Exception, /unsat/)
      end

      # It solves, so anything #model was holding is stale afterwards
      it "invalidates the model" do
        solver.assert p
        expect(solver).to be_satisfiable
        solver.consequences([p])
        expect{ solver.model }.to raise_error(Z3::Exception, /need to check/)
      end
    end

    describe "#cube" do
      let(:p) { Z3.Bool("p") }
      let(:q) { Z3.Bool("q") }

      it "enumerates case splits, ending with false" do
        solver.assert Z3.Or(p, q)
        cubes = 3.times.map { solver.cube.map(&:to_s) }
        # Z3 picks which literal to split on, so only the shape is checked
        expect(cubes.map(&:size)).to eq([1, 1, 1])
        expect(cubes.last).to eq(["false"])
        expect(cubes[0..1].flatten.sort).to eq(["not(q)", "q"])
      end

      it "splits on the variables it's given" do
        solver.assert Z3.Or(p, q)
        cube = solver.cube([p, q])
        expect(cube.size).to eq(1)
        expect(["p", "q"]).to include(cube[0].to_s)
      end

      # Nothing to case split on, rather than "no solution"
      it "is empty when the assertions already decide everything" do
        solver.assert p
        expect(solver.cube([p])).to eq([])
      end
    end

    # This is internal solver state, not a promise, so it's only checked on a case
    # simple enough that any version of Z3 has to see it the same way
    it "#units and #non_units" do
      solver.assert Z3.Bool("p")
      solver.assert Z3.Or(Z3.Bool("q"), Z3.Bool("r"))
      expect(solver.units.map(&:to_s)).to eq(["p"])
      expect(solver.non_units.map(&:to_s).sort).to eq(["q", "r"])
    end

    it "#trail" do
      simple = Solver.simple
      simple.assert Z3.Bool("p")
      expect(simple.trail).to eq([])
      expect(simple.check).to eq(:sat)
      # The rest of the trail is whatever the search happened to assign
      expect(simple.trail.map(&:to_s)).to include("p")
    end

    it "#trail is only implemented by Solver.simple" do
      expect{ solver.trail }.to raise_error(Z3::Exception)
    end

    describe "#simple?" do
      it "is only true for the plain SMT core" do
        expect(Solver.simple).to be_simple
        expect(Solver.new).to_not be_simple
        expect(Solver.for_logic("QF_LIA")).to_not be_simple
        expect(Solver.from_tactic(Tactic.named("smt"))).to_not be_simple
      end

      # A simplifier is preprocessing bolted on, the solver underneath is unchanged
      it "survives #with_simplifier" do
        simplifier = Simplifier.named("solve-eqs")
        expect(Solver.simple.with_simplifier(simplifier)).to be_simple
        expect(Solver.new.with_simplifier(simplifier)).to_not be_simple
      end
    end

    describe "#set_initial_value" do
      let(:simple) { Solver.simple }
      let(:x) { Z3.Int("x") }

      # The value Z3 picks unhinted is 0, so every one of these is the hint landing
      it "is the value the solver tries first" do
        simple.assert x >= 0
        simple.assert x <= 100
        simple.set_initial_value(x, 42)
        expect(simple).to be_satisfiable
        expect(simple.model[x].value).to eq(42)
      end

      it "returns the solver, so it chains" do
        expect(simple.set_initial_value(x, 42)).to equal(simple)
      end

      it "casts the value into the variable's sort" do
        c = Z3.Bool("c")
        expect(simple.set_initial_value(c, true)).to equal(simple)
        expect { simple.set_initial_value(x, "nope") }
          .to raise_error(Z3::Exception, "Can't convert String into Int")
        expect { simple.set_initial_value(x, true) }
          .to raise_error(Z3::Exception, "Can't convert true into Int")
      end

      # A hint and nothing more - it can't make a wrong answer right. Which of the
      # legal values Z3 falls back to isn't its own promise, so only the promise is
      # checked here
      it "is overridden when it doesn't fit the assertions" do
        simple.assert x >= 0
        simple.assert x <= 10
        simple.set_initial_value(x, 42)
        expect(simple).to be_satisfiable
        expect(simple.model[x].value).to be_between(0, 10)
      end

      it "can't make an unsatisfiable problem satisfiable" do
        simple.assert x > 5
        simple.assert x < 3
        simple.set_initial_value(x, 4)
        expect(simple).to be_unsatisfiable
      end

      it "survives repeated checks and push/pop" do
        simple.assert x >= 0
        simple.assert x <= 100
        simple.set_initial_value(x, 77)
        expect(simple).to be_satisfiable
        expect(simple.model[x].value).to eq(77)
        simple.push
        simple.assert x >= 10
        expect(simple).to be_satisfiable
        expect(simple.model[x].value).to eq(77)
        simple.pop
        expect(simple).to be_satisfiable
        expect(simple.model[x].value).to eq(77)
      end

      # Every other solver takes the call and quietly does nothing with it, which is
      # worse than refusing, so we refuse for them
      it "raises on any solver which would ignore it" do
        [solver, Solver.for_logic("QF_LIA"), Solver.from_tactic(Tactic.named("smt"))].each do |s|
          expect { s.set_initial_value(x, 42) }.to raise_error(
            Z3::Exception,
            "Only Solver.simple takes initial values, every other solver ignores them",
          )
        end
      end

      # Z3 accepts a compound expression here and then ignores it
      it "raises on anything which isn't a variable" do
        expect { simple.set_initial_value(x + 1, 42) }
          .to raise_error(Z3::Exception, "Initial values are for variables, and Int<x + 1> is not one")
        expect { simple.set_initial_value(Z3.Const(5), 42) }
          .to raise_error(Z3::Exception, "Initial values are for variables, and Int<5> is not one")
        expect { simple.set_initial_value(42, 42) }
          .to raise_error(Z3::Exception, "Initial values are for variables, and 42 is not one")
      end
    end

    # Cancelling a #check in progress needs another thread, which FFI won't give us
    # here, so this only pins down that an unused interrupt disturbs nothing
    it "#interrupt" do
      solver.assert a > 5
      expect(solver.interrupt).to be(solver)
      expect(solver).to be_satisfiable
    end

    it "#from_string" do
      solver.from_string("(declare-const c Int)(assert (> c 5))(assert (< c 7))")
      expect(solver.assertions.map(&:to_s)).to eq(["c > 5", "c < 7"])
    end

    # Whatever the string declares is an ordinary const in the one shared context
    it "#from_string declares consts Ruby can then use" do
      solver.from_string("(declare-const c Int)(assert (= c 6))")
      expect(solver).to be_satisfiable
      expect(solver.model[Z3.Int("c")].to_s).to eq("6")
    end

    # The parser's symbol table starts empty, so `a` has to be declared again even
    # though the solver already has an assertion about it
    it "#from_string adds to the assertions already there" do
      solver.assert a > 10
      solver.from_string("(declare-const a Int)(assert (< a 12))")
      expect(solver.assertions.map(&:to_s)).to eq(["a > 10", "a < 12"])
      expect(solver).to be_satisfiable
      expect(solver.model[a].to_s).to eq("11")
    end

    it "#from_string raises on anything that isn't SMT-LIB2" do
      expect{ solver.from_string("(assert (> nope") }.to raise_error(Z3::Exception)
    end

    it "#from_file" do
      solver.from_file("#{__dir__}/fixtures/solver_from_file.smt2")
      expect(solver).to be_satisfiable
      expect(solver.model[Z3.Int("from_file_y")].to_s).to eq("6")
    end

    it "#from_file raises when the file isn't there" do
      expect{ solver.from_file("#{__dir__}/fixtures/no-such-file.smt2") }.to raise_error(Z3::Exception)
    end

    describe ".simple" do
      it "solves like any other solver" do
        simple = Solver.simple
        simple.assert a + b == 4
        simple.assert a == 3
        expect(simple).to be_satisfiable
        expect(simple.model[b].to_s).to eq("1")
      end

      it "takes parameters" do
        expect(Solver.simple(random_seed: 42)).to be_a(Solver)
      end
    end

    describe ".for_logic" do
      it "solves problems inside its logic" do
        lia = Solver.for_logic("QF_LIA")
        lia.assert a > 3
        lia.assert a < 5
        expect(lia).to be_satisfiable
        expect(lia.model[a].to_s).to eq("4")
      end

      it "takes a Symbol too" do
        expect(Solver.for_logic(:QF_LIA)).to be_a(Solver)
      end

      # We have no logic name list to check against, so this comes straight from Z3
      it "raises on unknown logics" do
        expect{ Solver.for_logic("QF_NO_SUCH_LOGIC") }.to raise_error(Z3::Exception)
      end
    end

    describe ".from_tactic" do
      it "solves by running the tactic" do
        tactic = Solver.from_tactic(Tactic.new(LowLevel.mk_tactic("smt")))
        tactic.assert a + b == 4
        tactic.assert a == 3
        expect(tactic).to be_satisfiable
        expect(tactic.model[b].to_s).to eq("1")
      end

      it "raises unless given a Tactic" do
        expect{ Solver.from_tactic("smt") }.to raise_error(Z3::Exception, "Tactic required")
      end
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

    # Z3 used to answer :unknown here, which is what the example below still covers
    it "nonlinear satisfiability" do
      solver.assert a**3 == a
      expect(solver.check).to eq(:sat)
      expect(solver).to be_satisfiable
      expect(solver).to_not be_unsatisfiable
    end

    it "unknown satisfiability" do
      solver.assert a**a == a
      expect(solver.check).to eq(:unknown)
      expect{solver.satisfiable?}.to raise_error("Satisfiability unknown")
      expect{solver.unsatisfiable?}.to raise_error("Satisfiability unknown")
    end
  end
end
