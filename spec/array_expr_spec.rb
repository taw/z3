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
      # There are many ways to solve this
      if Z3.version_at_least?(4, 12)
        # 4.12.x
        expect([a[x] == 10, a[y] == 20]).to have_solution(
          a => "store(const(10), 3, 20)",
          x => "2",
          y => "3",
        )
      else
        # 4.8.x
        expect([a[x] == 10, a[y] == 20]).to have_solution(
          a => "store(const(10), 1, 20)",
          x => "0",
          y => "1",
        )
      end
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
