module Z3
  describe RealExpr do
    let(:a) { Z3.Real("a") }
    let(:b) { Z3.Real("b") }
    let(:c) { Z3.Real("c") }
    let(:x) { Z3.Bool("x") }

    it "+" do
      expect([a == 2, b == 4, c == a + b]).to have_solution(c => 6)
      expect([a == Rational(1,3), b == Rational(3,2), c == a + b]).to have_solution(c => "11/6")
    end

    it "-" do
      expect([a == 2, b == 4, c == a - b]).to have_solution(c => -2)
    end

    it "*" do
      expect([a == 2, b == 4, c == a * b]).to have_solution(c => 8)
    end

    it "/" do
      expect([a ==  10, b ==  3, c == a / b]).to have_solution(c => "10/3")
      expect([a == -10, b ==  3, c == a / b]).to have_solution(c => "-10/3")
      expect([a ==  10, b == -3, c == a / b]).to have_solution(c => "-10/3")
      expect([a == -10, b == -3, c == a / b]).to have_solution(c => "10/3")
    end

    it "==" do
      expect([a == 2, b == 2, x == (a == b)]).to have_solution(x => true)
      expect([a == 2, b == 3, x == (a == b)]).to have_solution(x => false)
    end

    it "!=" do
      expect([a == 2, b == 2, x == (a != b)]).to have_solution(x => false)
      expect([a == 2, b == 3, x == (a != b)]).to have_solution(x => true)
    end

    it ">" do
      expect([a == 3, b == 2, x == (a > b)]).to have_solution(x => true)
      expect([a == 2, b == 2, x == (a > b)]).to have_solution(x => false)
      expect([a == 1, b == 2, x == (a > b)]).to have_solution(x => false)
    end

    it ">=" do
      expect([a == 3, b == 2, x == (a >= b)]).to have_solution(x => true)
      expect([a == 2, b == 2, x == (a >= b)]).to have_solution(x => true)
      expect([a == 1, b == 2, x == (a >= b)]).to have_solution(x => false)
    end

    it "<" do
      expect([a == 3, b == 2, x == (a < b)]).to have_solution(x => false)
      expect([a == 2, b == 2, x == (a < b)]).to have_solution(x => false)
      expect([a == 1, b == 2, x == (a < b)]).to have_solution(x => true)
    end

    it "<=" do
      expect([a == 3, b == 2, x == (a <= b)]).to have_solution(x => false)
      expect([a == 2, b == 2, x == (a <= b)]).to have_solution(x => true)
      expect([a == 1, b == 2, x == (a <= b)]).to have_solution(x => true)
    end

    it "**" do
      expect([a == 3, b == 4, c == (a ** b)]).to have_solution(c => 81)
      expect([a == 81, b == 0.25, c == (a ** b)]).to have_solution(c => 3)
    end

    it "zero?" do
      expect([a == 0, x == a.zero?]).to have_solution(x => true)
      expect([a == 100, x == a.zero?]).to have_solution(x => false)
      expect([a == -200, x == a.zero?]).to have_solution(x => false)
    end

    it "nonzero?" do
      expect([a == 0, x == a.nonzero?]).to have_solution(x => false)
      expect([a == 100, x == a.nonzero?]).to have_solution(x => true)
      expect([a == -200, x == a.nonzero?]).to have_solution(x => true)
    end

    it "positive?" do
      expect([a == 0, x == a.positive?]).to have_solution(x => false)
      expect([a == 100, x == a.positive?]).to have_solution(x => true)
      expect([a == -200, x == a.positive?]).to have_solution(x => false)
    end

    it "negative?" do
      expect([a == 0, x == a.negative?]).to have_solution(x => false)
      expect([a == 100, x == a.negative?]).to have_solution(x => false)
      expect([a == -200, x == a.negative?]).to have_solution(x => true)
    end

    it "abs" do
      expect([a == 3, b == 2, c == (a - b).abs]).to have_solution(c => 1)
      expect([a == 2, b == 3, c == (a - b).abs]).to have_solution(c => 1)
      expect([a == 2, b == 2, c == (a - b).abs]).to have_solution(c => 0)
    end

    it "unary -" do
      expect([a == 3, b == -a]).to have_solution(b => -3)
      expect([a == 0, b == -a]).to have_solution(b => 0)
      expect([a == 3.5, b == -a]).to have_solution(b => "-7/2")
      expect([a == Rational(4,3), b == -a]).to have_solution(b => "-4/3")
    end

    let(:sort) { RealSort.new }

    # SMT-LIB's to_int rounds towards negative infinity, which is Ruby's Float#floor
    # and not Ruby's Float#to_i
    it "floor" do
      i = Z3.Int("i")
      expect([i == sort.from_const(2.5).floor]).to have_solution(i => 2)
      expect([i == sort.from_const(2.0).floor]).to have_solution(i => 2)
      expect([i == sort.from_const(-2.5).floor]).to have_solution(i => -3)
      expect([i == sort.from_const(-2.0).floor]).to have_solution(i => -2)
      expect(sort.from_const(2.5).floor.sort).to eq(IntSort.new)
    end

    it "integer?" do
      expect([a == 2.0, x == a.integer?]).to have_solution(x => true)
      expect([a == -3, x == a.integer?]).to have_solution(x => true)
      expect([a == 2.5, x == a.integer?]).to have_solution(x => false)
      expect([a == Rational(1, 3), x == a.integer?]).to have_solution(x => false)
    end

    # There is no #value on Real - see #to_r and #to_f for why
    describe "reading a value back into Ruby" do
      # An irrational root, which Z3 answers with an algebraic number
      let(:root_two) do
        solver = Z3::Solver.new
        solver.assert(a * a == 2)
        solver.assert(a > 0)
        solver.satisfiable?
        solver.model[a]
      end

      it "#to_r is exact for rationals" do
        expect(sort.from_const(2.5).to_r).to eq(Rational(5, 2))
        expect(sort.from_const(Rational(1, 3)).to_r).to eq(Rational(1, 3))
        expect(sort.from_const(-3).to_r).to eq(Rational(-3, 1))
        # Simplified first, so it doesn't have to be written as a literal
        expect((sort.from_const(Rational(1, 3)) + sort.from_const(Rational(1, 6))).to_r).to eq(Rational(1, 2))
        expect{ a.to_r }.to raise_error(Z3::Exception, "Can't convert expression a into a number")
      end

      # The whole reason Real has no #value: this one is a perfectly good literal
      # with no exact Ruby equivalent at all
      it "#to_r refuses algebraic numbers rather than rounding them" do
        expect(root_two).to be_algebraic
        expect(sort.from_const(2.5)).to_not be_algebraic
        expect{ root_two.to_r }.to raise_error(Z3::Exception, /algebraic number .* exact Rational/)
      end

      it "#to_f always works, because a Float is allowed to be approximate" do
        expect(sort.from_const(2.5).to_f).to eq(2.5)
        expect(sort.from_const(Rational(1, 3)).to_f).to eq(1.0 / 3)
        expect(root_two.to_f).to eq(Math.sqrt(2))
      end

      it "#lower_bound / #upper_bound bracket an algebraic number" do
        expect(root_two.lower_bound(0)).to eq(Rational(11, 8))
        expect(root_two.upper_bound(0)).to eq(Rational(3, 2))
        expect(root_two.lower_bound ** 2).to be < 2
        expect(root_two.upper_bound ** 2).to be > 2
        # Asking for more precision has to give a tighter bracket, not a looser one
        expect(root_two.lower_bound(30)).to be > root_two.lower_bound(0)
        expect(root_two.upper_bound(30)).to be < root_two.upper_bound(0)
      end

      it "an exact value is its own bound" do
        expect(sort.from_const(Rational(1, 3)).lower_bound).to eq(Rational(1, 3))
        expect(sort.from_const(Rational(1, 3)).upper_bound).to eq(Rational(1, 3))
      end
    end
  end
end
