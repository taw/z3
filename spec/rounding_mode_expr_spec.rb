module Z3
  describe RoundingModeExpr do
    let(:sort) { RoundingModeSort.new }
    let(:a) { sort.var("a") }

    it "list all possible options" do
      expect([a == a]).to have_solutions([
        { a => sort.nearest_ties_away },
        { a => sort.nearest_ties_even },
        { a => sort.towards_zero },
        { a => sort.towards_negative },
        { a => sort.towards_positive },
      ])
    end
  end
end
