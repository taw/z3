module Z3
  describe Goal do
    it "basic functionality" do
      g = Goal.new
      g.assert Z3.Int("x") == 3
      expect(g.num_exprs).to eq(3)
      expect(g.size).to eq(1)
      expect(g.depth).to eq(0)
      expect(g.precision).to eq(0)
      expect(g.to_s).to eq("(goal\n  (= x 3))")
      expect(g.decided_sat?).to eq(false)
      expect(g.decided_unsat?).to eq(false)
      expect(g.inconsistent?).to eq(false)
      expect(g.formula(0).to_s).to eq("x = 3")
    end
  end
end
