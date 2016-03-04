# Solver and Model specs are codependent, so half of functionality of each is tested in other class's tests
describe Z3::Solver do
  let(:solver) { Z3::Solver.new }
  let(:a) { Z3.Int("a") }
  let(:b) { Z3.Int("b") }

  it "basic functionality" do
    solver.assert(a == b)
    expect(solver.check).to eq(:sat)
    solver.assert(a != b)
    expect(solver.check).to eq(:unsat)
  end

  it "push/pop" do
    solver.assert(a == b)
    solver.push
    solver.assert(a != b)
    expect(solver.check).to eq(:unsat)
    solver.pop
    expect(solver.check).to eq(:sat)
  end
end
