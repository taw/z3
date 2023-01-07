module Z3
  describe IntExpr do
    let(:a) { Z3.Int("a") }
    let(:b) { Z3.Int("b") }
    let(:c) { Z3.Int("c") }
    let(:x) { Z3.Bool("x") }

    it "+" do
      expect([a == 2, b == 4, c == a + b]).to have_solution(c => 6)
    end

    it "-" do
      expect([a == 2, b == 4, c == a - b]).to have_solution(c => -2)
    end

    it "*" do
      expect([a == 2, b == 4, c == a * b]).to have_solution(c => 8)
    end

    it "/" do
      expect([a ==  10, b ==  3, c == a / b]).to have_solution(c =>  3)
      expect([a == -10, b ==  3, c == a / b]).to have_solution(c => -4)
      expect([a ==  10, b == -3, c == a / b]).to have_solution(c => -3)
      expect([a == -10, b == -3, c == a / b]).to have_solution(c =>  4)
    end

    # Can't say these make much sense, but let's document what Z3 actually does
    it "rem" do
      expect([a ==  10, b ==  3, c == a.rem(b)]).to have_solution(c => 10 -  3 *  3)
      expect([a == -10, b ==  3, c == a.rem(b)]).to have_solution(c =>-10 -  3 * -4)
      expect([a ==  10, b == -3, c == a.rem(b)]).to have_solution(c =>-( 10 - -3 * -3))
      expect([a == -10, b == -3, c == a.rem(b)]).to have_solution(c =>-(-10 - -3 *  4))
    end

    it "mod" do
      expect([a ==  10, b ==  3, c == a.mod(b)]).to have_solution(c => 1)
      expect([a ==  10, b == -3, c == a.mod(b)]).to have_solution(c => 1)
      expect([a == -10, b ==  3, c == a.mod(b)]).to have_solution(c => 2)
      expect([a == -10, b == -3, c == a.mod(b)]).to have_solution(c => 2)
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
    end

    it "unary -" do
      expect([a == 3, b == -a]).to have_solution(b => -3)
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

    it "simplify" do
      a = Z3.Const(5)
      b = Z3.Const(3)
      expect((a+b).inspect).to eq("Int<5 + 3>")
      expect((a+b).simplify.inspect).to eq("Int<8>")
    end

    it "to_i" do
      expect{Z3.Int("a").to_i}.to raise_error(Z3::Exception)
      expect(Z3.Const(2).to_i).to eq(2)
      expect((Z3.Const(2) + Z3.Const(40)).to_i).to eq(42)
    end
  end
end
