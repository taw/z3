describe Z3::IntValue do
  let(:a) { Z3::Int("a") }
  let(:b) { Z3::Int("b") }
  let(:c) { Z3::Int("c") }

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
end
