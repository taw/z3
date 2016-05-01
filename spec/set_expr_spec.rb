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

    # FIXME: This is not even real spec at this point, just a no-crash-spec
    it "union" do
      expect([
        a.include?(1),
        a.include?(2),
        b.include?(2),
        b.include?(3),
        c == a.union(b),
      ]).to have_solution(
        a => "as-array",
        b => "as-array",
        c => "as-array",
      )
    end

    it "difference" do
      expect([
        a.include?(1),
        a.include?(2),
        b.include?(2),
        b.include?(3),
        c == a.difference(b),
      ]).to have_solution(
        a => "as-array",
        b => "as-array",
        c => "as-array",
      )
    end

    it "intersection" do
      expect([
        a.include?(1),
        a.include?(2),
        b.include?(2),
        b.include?(3),
        c == a.intersection(b),
      ]).to have_solution(
        a => "as-array",
        b => "as-array",
        c => "as-array",
      )
    end
  end
end
