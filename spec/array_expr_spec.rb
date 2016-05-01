module Z3
  describe ArrayExpr do
    let(:sort) { ArraySort.new(IntSort.new, IntSort.new) }
    let(:a) { sort.var("a") }
    let(:b) { sort.var("b") }
    let(:c) { sort.var("c") }
    let(:x) { Z3::Bool("x") }

    # TODO: Formatting is dreadful
    it "== and !=" do
      expect([a == b, b != c]).to have_solution(
        a => "store(const(0), 0, 1)",
        b => "store(const(0), 0, 1)",
        c => "const(0)",
      )
    end
  end
end
