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
    expect(model.model_eval(a).to_s).to eq("2")
    expect(model.model_eval(b).to_s).to eq("4")
    expect(model.model_eval(c).to_s).to eq("c")
    expect(model.model_eval(a, true).to_s).to eq("2")
    expect(model.model_eval(b, true).to_s).to eq("4")
    expect(model.model_eval(c, true).to_s).to eq("0")
  end

  it "#to_s" do
    solver.assert(a == 2)
    solver.assert(b == a+2)
    expect(solver.check).to eq(:sat)
    expect(model.to_s).to eq("Z3::Model<a=2, b=4>")
    expect(model.inspect).to eq("Z3::Model<a=2, b=4>")
  end
end
