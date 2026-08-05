module Z3
  describe CharExpr do
    let(:sort) { CharSort.new }
    let(:a) { sort.from_const("a") }
    let(:b) { sort.from_const("b") }
    let(:c) { sort.var("c") }
    let(:i) { Z3.Int("i") }
    let(:x) { Z3.Bool("x") }

    it "to_i is the code point, as a Z3 Int" do
      expect([i == a.to_i]).to have_solution(i => 97)
      expect([i == sort.from_const("中").to_i]).to have_solution(i => 0x4e2d)
      expect(a.to_i.sort).to eq(IntSort.new)
    end

    # Z3 won't reduce char.to_bv in a model, so this checks the constraint instead
    it "to_bv is 18 bits, as wide as Z3's alphabet goes" do
      expect(a.to_bv.sort).to eq(BitvecSort.new(18))
      expect([a.to_bv == 97]).to have_solution({})
      expect([a.to_bv == 98]).to have_no_solution
    end

    it "digit?" do
      expect([x == sort.from_const("7").digit?]).to have_solution(x => true)
      expect([x == a.digit?]).to have_solution(x => false)
      expect([c.digit?, c.to_i == 51]).to have_solution(c => sort.from_const("3"))
    end

    it "comparisons" do
      expect([x == (a <= b)]).to have_solution(x => true)
      expect([x == (a <  b)]).to have_solution(x => true)
      expect([x == (a >= b)]).to have_solution(x => false)
      expect([x == (a >  b)]).to have_solution(x => false)
      expect([x == (a <= a)]).to have_solution(x => true)
      expect([x == (a <  a)]).to have_solution(x => false)
      expect([x == (a >= a)]).to have_solution(x => true)
    end

    # Unlike `==`, which goes through the generic coercion and has no way to guess
    # that "a" means a Char rather than a String
    it "comparisons take a Ruby String or code point on the right" do
      expect([x == (a < "b")]).to have_solution(x => true)
      expect([x == (a >= 97)]).to have_solution(x => true)
      expect([x == (a > "b")]).to have_solution(x => false)
      expect{ a == "a" }.to raise_error(ArgumentError)
      expect{ a < "bc" }.to raise_error(Z3::Exception, "Only single character strings can be converted to Char")
    end

    it "is usable as a constraint the solver has to satisfy" do
      expect([c > "a", c < "c"]).to have_solution(c => sort.from_const("b"))
    end
  end
end
