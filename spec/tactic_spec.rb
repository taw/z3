module Z3
  describe Tactic do
    it "constructors" do
      expect(Tactic.fail).to be_a Tactic
      expect(Tactic.fail_if_not_decided).to be_a Tactic
      expect(Tactic.skip).to be_a Tactic
    end

    it "names" do
      expect(Tactic.names).to include("simplify", "split-clause", "solve-eqs")
      expect(Tactic.names.size).to eq(LowLevel.get_num_tactics)
    end

    it "named" do
      expect(Tactic.named("simplify")).to be_a Tactic
      expect(Tactic.new("simplify")).to be_a Tactic
      expect{Tactic.named("no-such-tactic")}
        .to raise_error(Z3::Exception, /\Ano-such-tactic not on list of known tactics, available: /)
      expect{Tactic.new(42)}
        .to raise_error(Z3::Exception, "Tactic name or pointer expected, got Integer")
    end

    it "descriptions" do
      expect(Tactic.description("simplify")).to eq("apply simplification rules.")
      expect{Tactic.description("no-such-tactic")}
        .to raise_error(Z3::Exception, /\Ano-such-tactic not on list of known tactics, available: /)
    end

    it "combinators" do
      probe = Probe.named("is-qfbv")
      expect(Tactic.skip.and_then(Tactic.skip)).to be_a Tactic
      expect(Tactic.skip.or_else(Tactic.fail)).to be_a Tactic
      expect(Tactic.skip.parallel_and_then(Tactic.skip)).to be_a Tactic
      expect(Tactic.skip.repeat(2)).to be_a Tactic
      expect(Tactic.skip.try_for(100)).to be_a Tactic
      expect(Tactic.fail_if(probe)).to be_a Tactic
      expect(Tactic.when(probe, Tactic.skip)).to be_a Tactic
      expect(Tactic.cond(probe, Tactic.skip, Tactic.fail)).to be_a Tactic
      expect(Tactic.par_or(Tactic.fail, Tactic.skip)).to be_a Tactic
    end

    it ".par_or requires at least one tactic" do
      expect{Tactic.par_or}.to raise_error(Z3::Exception, "At least one tactic required")
      expect{Tactic.par_or(Tactic.skip, 42)}.to raise_error(Z3::Exception, "Tactic required")
    end

    describe "parameters" do
      let(:tactic) { Tactic.named("simplify") }

      it "#param_descrs" do
        expect(tactic.param_descrs).to be_a ParamDescrs
        expect(tactic.param_descrs.names).to include("elim_and")
        expect(tactic.param_descrs.kind("elim_and")).to eq(:bool)
      end

      # Tactics are immutable, so this builds a new one rather than changing this one
      it "#using_params" do
        expect(tactic.using_params(elim_and: true)).to be_a Tactic
        expect(tactic.using_params(Params.new(elim_and: true))).to be_a Tactic
        expect{tactic.using_params(no_such_param: true)}
          .to raise_error(Z3::Exception, "Unknown parameter `no_such_param'")
      end
    end

    describe "#apply" do
      let(:x) { Z3.Int("x") }
      let(:y) { Z3.Int("y") }
      let(:goal) do
        Goal.new.tap do |goal|
          goal.assert x > 0
          goal.assert (x < 3) | (y < 0)
        end
      end

      it "returns the subgoals which replace the goal" do
        result = Tactic.named("split-clause").apply(goal)
        expect(result).to be_a ApplyResult
        expect(result.map{|subgoal| subgoal.map(&:to_s) })
          .to eq([["x > 0", "x < 3"], ["x > 0", "y < 0"]])
      end

      it "leaves the goal it was applied to alone" do
        Tactic.named("split-clause").apply(goal)
        expect(goal.map(&:to_s)).to eq(["x > 0", "or(x < 3, y < 0)"])
      end

      it "takes parameters" do
        expect(Tactic.named("simplify").apply(goal, elim_and: true)).to be_a ApplyResult
        expect{Tactic.named("simplify").apply(goal, no_such_param: true)}
          .to raise_error(Z3::Exception, "Unknown parameter `no_such_param'")
      end

      it "requires a goal" do
        expect{Tactic.named("simplify").apply(42)}.to raise_error(Z3::Exception, "Goal required")
      end

      # A tactic which can't do anything with the goal fails, and Z3 says so itself
      it "raises when the tactic fails" do
        expect{Tactic.fail.apply(goal)}.to raise_error(Z3::Exception)
      end
    end

    it "survives allocation of other tactics" do
      tactic = Tactic.named("simplify")
      500.times { Tactic.skip }
      GC.start
      expect(tactic.help).to include("simplify")
    end
  end
end
