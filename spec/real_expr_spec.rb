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
  end
end
