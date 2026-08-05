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

    describe "functions in the model" do
      let(:f) { Z3.Function("f", IntSort.new, IntSort.new) }

      before do
        solver.assert f[1] == 10
        solver.assert f[2] == 20
        solver.assert a == 5
        expect(solver).to be_satisfiable
      end

      it "counts them" do
        expect(model.num_consts).to eq(1)
        expect(model.num_funcs).to eq(1)
        expect(model.funcs.map(&:name)).to eq(["f"])
      end

      # Z3 picks one of the values as the fallback and lists only the exceptions,
      # so the entries are not the whole function - #default is the rest of it
      it "#func_interp is a Hash whose default is Z3's else branch" do
        interp = model.func_interp(f)
        expect(interp).to be_a(Hash)
        expect(interp.keys.flatten.map(&:to_i)).to eq([2])
        expect(interp[[Z3.Const(2)]]).to stringify("20")
        expect(interp.default).to stringify("10")
        # Which means arguments the model never pinned down still answer
        expect(interp[[Z3.Const(1)]]).to stringify("10")
        expect(interp[[Z3.Const(99)]]).to stringify("10")
      end

      it "#func_interp raises for anything it can't interpret" do
        expect{ model.func_interp(42) }.to raise_error(Z3::Exception, "FuncDecl expected, got Integer")
        expect{ model.func_interp(Z3.Function("g", IntSort.new, IntSort.new)) }
          .to raise_error(Z3::Exception, "Model has no interpretation for g")
      end

      # `each` used to stop at consts, so a function was invisible in the model
      it "#each covers consts and functions alike" do
        consts = []
        model.each_const { |name, value| consts << [name.to_s, value.to_s] }
        funcs = []
        model.each_func { |decl, interp| funcs << [decl.name, interp.default.to_s] }
        expect(consts).to eq([["a", "5"]])
        expect(funcs).to eq([["f", "10"]])
        expect(model.to_a.size).to eq(2)
        expect(model.map { |name, _| name.to_s }).to eq(["a", "f"])
      end

      # Hash#inspect drops the default, and for a function the default is most of it
      it "#to_s prints the else branch" do
        expect(model.to_s).to eq("Z3::Model<a=5, f={(2) => 20, else => 10}>")
      end

      # It would need a quantifier to say "f differs somewhere", so it only negates
      # the constants and says so
      it "#! only negates constants" do
        expect(!model).to be_same_as(Z3.Or(a != 5))
      end
    end

    describe "uninterpreted sorts in the model" do
      let(:person) { UninterpretedSort.new("Person") }
      let(:alice) { person.var("alice") }
      let(:bob) { person.var("bob") }

      before do
        solver.assert Z3.Distinct(alice, bob)
        expect(solver).to be_satisfiable
      end

      it "lists the sorts it had to invent elements for" do
        expect(model.num_sorts).to eq(1)
        expect(model.sorts).to eq([person])
      end

      # Z3 only ever needs finitely many, so this is the whole sort for this model
      it "#sort_universe gives every element" do
        universe = model.sort_universe(person)
        expect(universe.size).to eq(2)
        expect(universe.map(&:sort).uniq).to eq([person])
        expect(universe.map(&:to_s).sort).to eq(["Person!val!0", "Person!val!1"])
      end

      it "#sort_universe raises unless given a Sort" do
        expect{ model.sort_universe("Person") }.to raise_error(Z3::Exception, "Sort expected, got String")
      end
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
