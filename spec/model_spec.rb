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

    it "#!" do
      solver.assert(a == 2)
      solver.assert(b == a+2)
      expect(solver).to be_satisfiable
      expect(!model).to be_same_as((a != 2) | (b != 4))
    end

    it "stays valid after the solver produces another model" do
      solver.assert(a == 2)
      expect(solver).to be_satisfiable
      first = solver.model
      solver.assert(b == 4)
      expect(solver).to be_satisfiable
      second = solver.model
      expect(second.to_s).to eq("Z3::Model<a=2, b=4>")
      # Without model_inc_ref the first model is reclaimed here, and reading it segfaults
      expect(first.to_s).to eq("Z3::Model<a=2>")
      expect(first[a]).to be_same_as(Z3.Const(2))
    end

    it "survives garbage collection while other models are discarded" do
      solver.assert(a == 2)
      expect(solver).to be_satisfiable
      kept = solver.model
      100.times do
        solver.send(:reset_model!)
        expect(solver).to be_satisfiable
        solver.model
      end
      GC.start
      expect(kept.to_s).to eq("Z3::Model<a=2>")
    end

    it "keeps every model of an enumeration readable" do
      solver.assert(a >= 0)
      solver.assert(a < 5)
      models = []
      while solver.satisfiable?
        models << solver.model
        solver.assert(!models.last)
      end
      expect(models.size).to eq(5)
      expect(models.map{|m| m[a].to_i}.sort).to eq([0, 1, 2, 3, 4])
    end

    it "#! on a model with no consts" do
      solver.assert(Z3.Bool("p") | true)
      expect(solver).to be_satisfiable
      expect(model.num_consts).to eq(0)
      expect(!model).to be_same_as(Z3.False)
    end

    it "#! terminates enumeration of a model with no consts" do
      solver.assert(Z3.Bool("p") | true)
      solutions = []
      while solver.satisfiable?
        solutions << solver.model.to_a
        solver.assert(!solver.model)
        raise "Enumeration failed to terminate" if solutions.size > 5
      end
      expect(solutions).to eq([[]])
    end
  end
end
