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

    # It doesn't match Ruby on negative right side, but nobody does modulo a negative anyway
    # Python Z3 API does the same thing
    it "%" do
      expect([a ==  10, b ==  3, c == a % b]).to have_solution(c => 1)
      expect([a ==  10, b == -3, c == a % b]).to have_solution(c => 1)
      expect([a == -10, b ==  3, c == a % b]).to have_solution(c => 2)
      expect([a == -10, b == -3, c == a % b]).to have_solution(c => 2)
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

    # Z3 spells it the other way round, as "3 divides 12"
    # The divisor is a decl parameter, so it has to be printed explicitly or every
    # `divisible_by?` looks the same
    it "divisible_by? and to_bv print their parameter" do
      expect(Z3.Int("a").divisible_by?(3).to_s).to eq("divisible(a, 3)")
      expect(Z3.Int("a").divisible_by?(5).to_s).to eq("divisible(a, 5)")
      expect(Z3.Int("a").to_bv(8).to_s).to eq("int_to_bv(a, 8)")
    end

    it "divisible_by?" do
      expect([a == 12, x == a.divisible_by?(3)]).to have_solution(x => true)
      expect([a == 12, x == a.divisible_by?(5)]).to have_solution(x => false)
      expect([a == 0, x == a.divisible_by?(7)]).to have_solution(x => true)
      expect([a == -12, x == a.divisible_by?(3)]).to have_solution(x => true)
      expect([a.divisible_by?(4), a > 10, a < 15]).to have_solution(a => 12)
    end

    it "simplify" do
      a = Z3.Const(5)
      b = Z3.Const(3)
      expect((a+b).inspect).to eq("Int<5 + 3>")
      expect((a+b).simplify.inspect).to eq("Int<8>")
    end

    # #value is the name every sort uses for "the Ruby object behind this literal",
    # and on Int it's the same method as #to_i
    it "value" do
      expect{Z3.Int("a").value}.to raise_error(Z3::Exception, "Can't convert expression a into Integer")
      expect(Z3.Const(2).value).to eq(2)
      expect((Z3.Const(2) + Z3.Const(40)).value).to eq(42)
      expect(Z3.Const(2).method(:value).original_name).to eq(:to_i)
    end

    it "to_i" do
      expect{Z3.Int("a").to_i}.to raise_error(Z3::Exception)
      expect(Z3.Const(2).to_i).to eq(2)
      expect((Z3.Const(2) + Z3.Const(40)).to_i).to eq(42)
    end
  end
end
