describe Z3::RealValue do
  let(:a) { Z3::Real("a") }
  let(:b) { Z3::Real("b") }
  let(:c) { Z3::Real("c") }
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
end
