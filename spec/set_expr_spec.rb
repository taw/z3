module Z3
  describe SetExpr do
    let(:sort) { SetSort.new(IntSort.new) }
    let(:a) { sort.var("a") }
    let(:b) { sort.var("b") }
    let(:c) { sort.var("c") }
    let(:x) { Z3::Bool("x") }

    # TODO: Formatting is dreadful
    it "== and !=" do
      expect([a == b, b != c]).to have_solution(
        a => "store(const(false), 0, true)",
        b => "store(const(false), 0, true)",
        c => "const(false)",
      )
    end
  end
end
