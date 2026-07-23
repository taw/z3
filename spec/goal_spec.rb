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

    it "#to_dimacs" do
      g = Goal.new
      g.assert Z3.Or(Z3.Bool("p"), Z3.Bool("q"))
      # Z3 emits the name comments in whatever order it happens to iterate in
      expect(g.to_dimacs.lines.map(&:chomp).sort).to eq(["1 2 0", "c 1 p", "c 2 q", "p cnf 2 1"])
      expect(g.to_dimacs(false)).to eq("p cnf 2 1\n1 2 0")
    end

    it "survives allocation of other goals" do
      g = Goal.new
      g.assert Z3.Int("x") == 3
      100.times { Goal.new }
      GC.start
      expect(g.to_s).to eq("(goal\n  (= x 3))")
    end
  end
end
