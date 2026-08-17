module Z3
  describe Simplifier do
    it "names" do
      expect(Simplifier.names).to include("solve-eqs", "propagate-values", "bit2int")
      expect(Simplifier.names.size).to eq(LowLevel.get_num_simplifiers)
    end

    it "named" do
      expect(Simplifier.named("solve-eqs")).to be_a Simplifier
      expect(Simplifier.new("solve-eqs")).to be_a Simplifier
      expect{Simplifier.named("no-such-simplifier")}
        .to raise_error(Z3::Exception, /\Ano-such-simplifier not on list of known simplifiers, available: /)
      expect{Simplifier.new(42)}
        .to raise_error(Z3::Exception, "Simplifier name or pointer expected, got Integer")
    end

    it "descriptions" do
      expect(Simplifier.description("solve-eqs")).to eq("solve for variables.")
      expect{Simplifier.description("no-such-simplifier")}
        .to raise_error(Z3::Exception, /\Ano-such-simplifier not on list of known simplifiers, available: /)
    end

    it "#help" do
      expect(Simplifier.named("solve-eqs").help).to include("context_solve")
    end

    # The only combinator there is - a simplifier can't fail, so there's no or_else
    it "#and_then" do
      expect(Simplifier.named("solve-eqs").and_then(Simplifier.named("bit2int"))).to be_a Simplifier
      expect{Simplifier.named("solve-eqs").and_then(42)}
        .to raise_error(Z3::Exception, "Simplifier required")
    end

    describe "parameters" do
      let(:simplifier) { Simplifier.named("solve-eqs") }

      it "#param_descrs" do
        expect(simplifier.param_descrs).to be_a ParamDescrs
        expect(simplifier.param_descrs.names).to include("context_solve")
        expect(simplifier.param_descrs.kind("context_solve")).to eq(:bool)
      end

      it "#using_params" do
        expect(simplifier.using_params(context_solve: true)).to be_a Simplifier
        expect(simplifier.using_params(Params.new(context_solve: true))).to be_a Simplifier
        expect{simplifier.using_params(no_such_param: true)}
          .to raise_error(Z3::Exception, "Unknown parameter `no_such_param'")
      end
    end

    # Z3 below 5.0 gets `elim-unconstrained` wrong badly enough to be worth refusing
    # outright - see spec/upstream_bugs_spec.rb, which reaches past this class to
    # reproduce it. 5.0 fixed it, and there the refusal has to get out of the way.
    describe "unsound simplifiers" do
      if Z3.version_at_least?(5, 0)
        it "refuses nothing, because this Z3 has no known unsound simplifier" do
          expect(Simplifier.unsound).to eq({})
          expect(Simplifier.named("elim-unconstrained")).to be_a Simplifier
        end
      else
        it "refuses to build one" do
          expect{Simplifier.named("elim-unconstrained")}
            .to raise_error(Z3::Exception, /\Aelim-unconstrained is unsound in Z3 .* which doesn't satisfy the assertions\z/)
        end
      end

      # Z3 has it, so the list says so - #named is where it gets turned down
      it "still reports it in .names" do
        expect(Simplifier.names).to include("elim-unconstrained")
      end
    end

    describe "Solver#with_simplifier" do
      let(:x) { Z3.Int("x") }
      let(:y) { Z3.Int("y") }

      it "solves with the simplifier attached" do
        solver = Solver.new.with_simplifier(Simplifier.named("solve-eqs"))
        solver.assert x == y + 3
        solver.assert y > 0
        expect(solver.check).to eq(:sat)
        expect(solver.model.model_eval(x == y + 3, true).to_b).to be true
        expect(solver.model.model_eval(y > 0, true).to_b).to be true
      end

      it "takes a chain of them" do
        simplifier = Simplifier.named("solve-eqs").and_then(Simplifier.named("propagate-values"))
        solver = Solver.new.with_simplifier(simplifier)
        solver.assert x == y + 3
        solver.assert y > 0
        expect(solver.check).to eq(:sat)
        expect(solver.model.model_eval(x == y + 3, true).to_b).to be true
      end

      # Z3 returns a different solver rather than changing the one it was given
      it "returns a new solver and leaves the receiver alone" do
        original = Solver.new
        attached = original.with_simplifier(Simplifier.named("solve-eqs"))
        expect(attached).to be_a Solver
        expect(attached._solver).to_not eq(original._solver)
        attached.assert x > 5
        expect(original.assertions).to eq([])
      end

      it "works on every kind of solver" do
        expect(Solver.simple.with_simplifier(Simplifier.named("solve-eqs"))).to be_a Solver
        expect(Solver.for_logic("QF_LIA").with_simplifier(Simplifier.named("solve-eqs"))).to be_a Solver
        expect(Solver.from_tactic(Tactic.named("smt")).with_simplifier(Simplifier.named("solve-eqs"))).to be_a Solver
      end

      it "requires a simplifier" do
        expect{Solver.new.with_simplifier(42)}.to raise_error(Z3::Exception, "Simplifier required")
      end

      # Z3's own restriction, and its message says it better than we could
      it "has to come before anything is asserted" do
        solver = Solver.new
        solver.assert x > 1
        expect{solver.with_simplifier(Simplifier.named("solve-eqs"))}
          .to raise_error(Z3::Exception, /adding a simplifier to a solver with assertions is not allowed/)
      end
    end

    # Guards against a different one going wrong the way elim-unconstrained did, and
    # against .unsound naming something which was only ever fine
    it "every simplifier it will build returns models which satisfy the assertions" do
      refused, buildable = Simplifier.names.partition { |name| Simplifier.unsound.key?(name) }
      x, y = Z3.Int("x"), Z3.Int("y")

      unsound = buildable.reject do |name|
        solver = Solver.new.with_simplifier(Simplifier.named(name))
        solver.assert x == y + 3
        solver.assert y > 0
        solver.check == :sat &&
          solver.model.model_eval(x == y + 3, true).to_b &&
          solver.model.model_eval(y > 0, true).to_b
      end

      expect(unsound).to eq([])
      expect(refused).to eq(Simplifier.unsound.keys)
      # No exact count - which simplifiers Z3 registers varies by version, platform,
      # and build options, so pinning it just breaks on someone else's Z3. A floor is
      # enough to catch the list coming back empty or gutted.
      expect(buildable.size).to be >= 20
    end
  end
end
