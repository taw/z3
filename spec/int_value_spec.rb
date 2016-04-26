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
end
