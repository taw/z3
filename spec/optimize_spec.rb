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

    describe "#set_initial_value" do
      let(:b) { Z3.Bool("b") }
      let(:c) { Z3.Bool("c") }
      let(:v) { Z3.Bitvec("v", 8) }

      # Unhinted Z3 answers b=true, c=false here, so both halves of this are the hint
      it "is the value the solver tries first" do
        optimize.assert b | c
        optimize.set_initial_value(b, false)
        optimize.set_initial_value(c, true)
        expect(optimize).to be_satisfiable
        expect(optimize.model[b].to_b).to eq(false)
        expect(optimize.model[c].to_b).to eq(true)
      end

      it "works for Bitvec as well, and alongside an objective" do
        y = Z3.Int("y")
        optimize.assert v.unsigned_gt(0)
        optimize.assert y >= 0
        optimize.assert y <= 9
        optimize.maximize(y)
        optimize.set_initial_value(v, 200)
        expect(optimize).to be_satisfiable
        expect(optimize.model[v].unsigned_to_i).to eq(200)
        expect(optimize.model[y].value).to eq(9)
      end

      it "returns the optimize, so it chains" do
        expect(optimize.set_initial_value(b, true)).to equal(optimize)
      end

      it "casts the value into the variable's sort" do
        expect(optimize.set_initial_value(v, 3)).to equal(optimize)
        expect { optimize.set_initial_value(b, "nope") }
          .to raise_error(Z3::Exception, "Can't convert String into Bool")
      end

      # A hint and nothing more - it can't make a wrong answer right
      it "is overridden when it doesn't fit the assertions" do
        optimize.assert b
        optimize.set_initial_value(b, false)
        expect(optimize).to be_satisfiable
        expect(optimize.model[b].to_b).to eq(true)
      end

      it "can't make an unsatisfiable problem satisfiable" do
        optimize.assert b
        optimize.assert ~b
        optimize.set_initial_value(b, true)
        expect(optimize).to be_unsatisfiable
      end

      # Z3 accepts a compound expression here and then ignores it
      it "raises on anything which isn't a variable" do
        expect { optimize.set_initial_value(b | c, true) }
          .to raise_error(Z3::Exception, "Initial values are for variables, and Bool<or(b, c)> is not one")
        expect { optimize.set_initial_value(v + 1, 3) }
          .to raise_error(Z3::Exception, "Initial values are for variables, and Bitvec(8)<v + 1> is not one")
        expect { optimize.set_initial_value(42, 42) }
          .to raise_error(Z3::Exception, "Initial values are for variables, and 42 is not one")
      end

      # Z3 takes these and either throws the hint away or answers with a model which
      # fails its own assertions - `spec/upstream_bugs_spec.rb` reproduces both
      it "refuses Int and Real, which Z3 gets wrong" do
        message = "Optimize drops Int initial values and answers unsoundly for Real ones, " \
          "use Solver.simple for an arithmetic warm start"
        expect { optimize.set_initial_value(a, 42) }.to raise_error(Z3::Exception, message)
        expect { optimize.set_initial_value(Z3.Real("r"), 42) }.to raise_error(Z3::Exception, message)
      end
    end

    it "#from_string" do
      optimize.from_string("(declare-const c Int)(assert (> c 5))(assert (< c 7))")
      expect(optimize.assertions.map(&:to_s)).to eq(["c > 5", "c < 7"])
    end

    # Whatever the string declares is an ordinary const in the one shared context
    it "#from_string declares consts Ruby can then use" do
      optimize.from_string("(declare-const c Int)(assert (= c 6))")
      expect(optimize).to be_satisfiable
      expect(optimize.model[Z3.Int("c")].to_s).to eq("6")
    end

    # The parser's symbol table starts empty, so `a` has to be declared again even
    # though the optimize already has an assertion about it
    it "#from_string adds to the assertions already there" do
      optimize.assert a > 10
      optimize.from_string("(declare-const a Int)(assert (< a 12))")
      expect(optimize.assertions.map(&:to_s)).to eq(["a > 10", "a < 12"])
      expect(optimize).to be_satisfiable
      expect(optimize.model[a].to_s).to eq("11")
    end

    # Unlike Solver's, this parser knows the optimization commands too
    it "#from_string takes objectives and soft constraints as well as assertions" do
      optimize.from_string(
        "(declare-const c Int)(assert (>= c 0))(assert (<= c 10))" \
        "(assert-soft (= c 3) :weight 5)(minimize c)"
      )
      expect(optimize).to be_satisfiable
      expect(optimize.model[Z3.Int("c")].to_s).to eq("3")
    end

    it "#from_string raises on anything that isn't SMT-LIB2" do
      expect{ optimize.from_string("(assert (> nope") }.to raise_error(Z3::Exception)
    end

    it "#from_file" do
      optimize.from_file("#{__dir__}/fixtures/optimize_from_file.smt2")
      expect(optimize).to be_satisfiable
      expect(optimize.model[Z3.Int("optimize_from_file_x")].to_s).to eq("10")
    end

    it "#from_file raises when the file isn't there" do
      expect{ optimize.from_file("#{__dir__}/fixtures/no-such-file.smt2") }.to raise_error(Z3::Exception)
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

      # Optimize takes far fewer parameters than Solver - 89 fewer on 5.1 - and this
      # is one Solver has. Which ones differ moves between versions: `arith.nl` used
      # to be an example and stopped being one in 5.1, when Optimize gained the whole
      # `arith.*` group. `unsat_core` is picked because Optimize has no unsat cores
      # to configure at all.
      it "#set_params rejects parameters Optimize does not take" do
        expect{ optimize.set_params(unsat_core: true) }
          .to raise_error(Z3::Exception, "Unknown parameter `unsat_core'")
      end
    end
  end
end
