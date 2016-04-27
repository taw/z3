describe Z3::IntExpr do
  let(:a) { Z3::Int("a") }
  let(:b) { Z3::Int("b") }
  let(:c) { Z3::Int("c") }
  let(:x) { Z3::Bool("x") }

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
end
