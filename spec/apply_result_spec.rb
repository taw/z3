module Z3
  describe ApplyResult do
    let(:x) { Z3.Int("x") }
    let(:y) { Z3.Int("y") }
    let(:goal) do
      Goal.new.tap do |goal|
        goal.assert x > 0
        goal.assert (x < 3) | (y < 0)
      end
    end
    let(:result) { Tactic.named("split-clause").apply(goal) }

    it "#size" do
      expect(result.size).to eq(2)
    end

    it "#[]" do
      expect(result[0]).to be_a Goal
      expect(result[0].map(&:to_s)).to eq(["x > 0", "x < 3"])
      expect(result[1].map(&:to_s)).to eq(["x > 0", "y < 0"])
      expect{result[2]}.to raise_error(Z3::Exception, "Out of range")
      expect{result[-1]}.to raise_error(Z3::Exception, "Out of range")
    end

    it "is Enumerable" do
      expect(result.count).to eq(2)
      expect(result.map(&:size)).to eq([2, 2])
      expect(result.each).to be_a Enumerator
      expect(result.to_a.map{|subgoal| subgoal.map(&:to_s) })
        .to eq([["x > 0", "x < 3"], ["x > 0", "y < 0"]])
    end

    # Z3's own rendering, so it's the SMT-LIB form rather than the Printer's
    it "#to_s" do
      expect(result.to_s).to eq("(goals\n(goal\n  (> x 0)\n  (< x 3))\n(goal\n  (> x 0)\n  (< y 0))\n)")
    end

    it "#inspect" do
      expect(result.inspect).to eq("Z3::ApplyResult<2 subgoals>")
      expect(Tactic.skip.apply(goal).inspect).to eq("Z3::ApplyResult<1 subgoal>")
    end

    # No subgoals at all means there is nothing left to prove
    it "reports a decided goal" do
      unsat = Goal.new
      unsat.assert Z3.Bool("p") & ~Z3.Bool("p")
      expect(Tactic.named("simplify").apply(unsat).first.decided_unsat?).to be true

      sat = Goal.new
      sat.assert Z3.Bool("p") | ~Z3.Bool("p")
      expect(Tactic.named("simplify").apply(sat).first.decided_sat?).to be true
    end

    it "survives allocation of other apply results" do
      500.times { Tactic.skip.apply(goal) }
      GC.start
      expect(result.size).to eq(2)
      expect(result[0].map(&:to_s)).to eq(["x > 0", "x < 3"])
    end
  end
end
