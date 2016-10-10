# Solver and Model specs are codependent, so half of functionality of each is tested in other class's tests
module Z3
  describe Model do
    let(:solver) { Solver.new }
    let(:a) { Z3.Int("a") }
    let(:b) { Z3.Int("b") }
    let(:c) { Z3.Int("c") }
    let(:model) { solver.model }

    it "knows how many variables are in the model" do
      solver.assert(a == 2)
      solver.assert(b == a+2)
      expect(solver).to be_satisfiable
      expect(model.num_consts).to eq(2)
      expect(model.num_funcs).to eq(0)
      expect(model.num_sorts).to eq(0)
    end

    it "can evaluate variables" do
      solver.assert(a == 2)
      solver.assert(b == a+2)
      expect(solver).to be_satisfiable
      expect(model.model_eval(a)).to be_same_as(Z3.Const(2))
      expect(model.model_eval(b)).to be_same_as(Z3.Const(4))
      expect(model.model_eval(c)).to be_same_as(c)
      expect(model.model_eval(a, true)).to be_same_as(Z3.Const(2))
      expect(model.model_eval(b, true)).to be_same_as(Z3.Const(4))
      expect(model.model_eval(c, true)).to be_same_as(Z3.Const(0))
    end

    it "#to_a" do
      solver.assert(a == 2)
      solver.assert(b == a+2)
      expect(solver).to be_satisfiable
      expect(model.to_a).to be_same_as([[Z3.Int("a"), Z3.Const(2)], [Z3.Int("b"), Z3.Const(4)]])
    end

    it "#to_s" do
      solver.assert(a == 2)
      solver.assert(b == a+2)
      expect(solver).to be_satisfiable
      expect(model.to_s).to eq("Z3::Model<a=2, b=4>")
      expect(model.inspect).to eq("Z3::Model<a=2, b=4>")
    end
  end
end
