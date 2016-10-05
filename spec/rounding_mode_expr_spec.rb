module Z3
  describe RoundingModeExpr do
    let(:sort) { RoundingModeSort.new }
    let(:a) { sort.var("a") }

    it "list all possible options" do
      solver = Z3::Solver.new
      solutions = []
      while solver.check == :sat
        model = solver.model
        solution = model.model_eval(a, true)
        solutions << solution
        solver.assert a != solution
      end

      expect(solutions).to match([
        sort.nearest_ties_away,
        sort.nearest_ties_even,
        sort.towards_zero,
        sort.towards_negative,
        sort.towards_positive,
      ])
    end
  end
end
