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

    # Enumerating the formulas is how a subgoal gets back into a Solver
    it "is Enumerable over its formulas" do
      g = Goal.new
      g.assert Z3.Int("x") == 3
      g.assert Z3.Int("y") > 4
      expect(g.map(&:to_s)).to eq(["x = 3", "y > 4"])
      expect(g.count).to eq(2)
      expect(g.each).to be_a Enumerator
      expect(Goal.new.to_a).to eq([])
    end

    # A tactic's subgoal is a different problem to the one it started with, so a
    # model of the subgoal has to be converted back before it means anything
    describe "#convert_model" do
      let(:x) { Z3.Int("x") }
      let(:y) { Z3.Int("y") }
      # Models have to be enabled, or there's nothing recorded to convert with
      let(:goal) do
        Goal.new(true).tap do |goal|
          goal.assert x == y + 3
          goal.assert y > 0
          goal.assert y < 5
        end
      end

      it "undoes what the tactic did" do
        # solve-eqs eliminates one of the two variables entirely
        subgoal = Tactic.named("solve-eqs").apply(goal).first
        solver = Solver.new
        subgoal.each { |formula| solver.assert formula }
        expect(solver.check).to eq(:sat)
        expect(solver.model.to_a.size).to eq(1)

        model = subgoal.convert_model(solver.model)
        expect(model.to_a.size).to eq(2)
        expect(model[x].value).to eq(model[y].value + 3)
      end

      # Which makes the whole round trip available without solving the subgoal at all -
      # a model built by hand goes in, and comes back in terms of the original goal
      it "takes a model built by hand" do
        subgoal = Tactic.named("solve-eqs").apply(goal).first
        model = subgoal.convert_model(Model.new(x => 7))
        expect(model[x].value).to eq(7)
        expect(model[y].value).to eq(4)
        expect(model.model_eval(x == y + 3, true).to_b).to eq(true)
      end

      it "requires a model" do
        expect{goal.convert_model(42)}.to raise_error(Z3::Exception, "Model required")
      end
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
