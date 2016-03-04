# Solver and Model specs are codependent, so half of functionality of each is tested in other class's tests
describe Z3::Model do
  let(:solver) { Z3::Solver.new }
  let(:a) { Z3.Int("a") }
  let(:b) { Z3.Int("b") }
  let(:c) { Z3.Int("c") }
  let(:model) { solver.model }

  it "knows how many variables are in the model" do
    solver.assert(a == 2)
    solver.assert(b == a+2)
    expect(solver.check).to eq(:sat)
    expect(model.num_consts).to eq(2)
    expect(model.num_funcs).to eq(0)
    expect(model.num_sorts).to eq(0)
  end

  it "can evaluate variables" do
    solver.assert(a == 2)
    solver.assert(b == a+2)
    expect(solver.check).to eq(:sat)
    expect(model.model_eval(a).inspect).to eq("Z3::Ast<2 :: Int>")
    expect(model.model_eval(b).inspect).to eq("Z3::Ast<4 :: Int>")
    expect(model.model_eval(c).inspect).to eq("Z3::Ast<c :: Int>")
    expect(model.model_eval(a, true).inspect).to eq("Z3::Ast<2 :: Int>")
    expect(model.model_eval(b, true).inspect).to eq("Z3::Ast<4 :: Int>")
    expect(model.model_eval(c, true).inspect).to eq("Z3::Ast<0 :: Int>")
  end

  it "#to_s" do
    solver.assert(a == 2)
    solver.assert(b == a+2)
    expect(solver.check).to eq(:sat)
    expect(model.to_s).to eq("Z3::Model<a=2, b=4>")
    expect(model.inspect).to eq("Z3::Model<a=2, b=4>")
  end
end
