module Z3
  describe Tactic do
    it "constructors" do
      expect(Tactic.fail).to be_a Tactic
      expect(Tactic.fail_if_not_decided).to be_a Tactic
      expect(Tactic.skip).to be_a Tactic
    end

    it "descriptions" do
      expect(Tactic.description("simplify")).to eq("apply simplification rules.")
      # We have no tactic name list to check against, so this comes straight from Z3
      expect{Tactic.description("no-such-tactic")}.to raise_error(Z3::Exception)
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
    end

    it "survives allocation of other tactics" do
      tactic = Tactic.new(LowLevel.mk_tactic("simplify"))
      500.times { Tactic.skip }
      GC.start
      expect(tactic.help).to include("simplify")
    end

    it "can be applied to a goal" do
      goal = Goal.new
      goal.assert Z3.Int("x") == 3
      tactic = Tactic.new(LowLevel.mk_tactic("simplify"))
      500.times { Tactic.skip; Goal.new }
      GC.start
      expect(LowLevel.tactic_apply(tactic, goal)).to be_a FFI::Pointer
    end
  end
end
