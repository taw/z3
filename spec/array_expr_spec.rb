module Z3
  describe ArrayExpr do
    let(:sort) { ArraySort.new(IntSort.new, IntSort.new) }
    let(:a) { sort.var("a") }
    let(:b) { sort.var("b") }
    let(:c) { sort.var("c") }
    let(:x) { Z3::Int("x") }
    let(:y) { Z3::Int("y") }
    let(:z) { Z3::Int("z") }

    # TODO: Formatting is dreadful
    it "== and !=" do
      expect([a == b, b != c]).to have_solution(
        a => "store(const(0), 0, 1)",
        b => "store(const(0), 0, 1)",
        c => "const(0)",
      )
    end

    it "select" do
      expect([a.select(10) == 20]).to have_solution(
        a => "const(20)",
      )
      expect([a[10] == 20]).to have_solution(
        a => "const(20)",
      )
      # Forced x and y to specific values, otherwise this spec fails between versions
      expect([a[x] == 10, a[y] == 20, x == 30, y == 40]).to have_solution(
        a => "store(const(20), 30, 10)",
        #    "store(const(10), 40, 20)" would also work
        x => "30",
        y => "40",
      )
    end

    it "store" do
      expect([a == b.store(10, 20), x == a.select(10)]).to have_solution(
        x => 20,
      )
      expect([a == b.store(10, 20), x == a[10]]).to have_solution(
        x => 20,
      )
      expect([a == b.store(10, 20), x == a[y], y == 10]).to have_solution(
        x => 20,
      )
      expect([a == b.store(10, 20), x == a[y], x == 20]).to have_solution(
        x => 20,
        y => 10,
      )
    end
  end
end
