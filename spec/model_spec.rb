# Solver and Model specs are codependent, so half of functionality of each is tested in other class's tests
describe Z3::Model do
  let(:solver) { Z3::Solver.new }
  let(:a) { Z3::Ast.int("a") }
  let(:b) { Z3::Ast.int("b") }
  let(:c) { Z3::Ast.int("c") }
  let(:model) { solver.model }

  it "knows how many variables are in the model" do
    solver.assert(a == 2)
    solver.assert(b == a+2)
    expect(solver.check).to eq(:sat)
    expect(model.num_consts).to eq(2)
    expect(model.num_funcs).to eq(0)
    expect(model.num_sorts).to eq(0)
  end
end
