module Z3
  describe UninterpretedSort do
    let(:u) { UninterpretedSort.new("U") }
    let(:v) { UninterpretedSort.new("V") }

    it "to_s" do
      expect(u.to_s).to eq("U")
      expect(v.to_s).to eq("V")
    end

    it "inspect" do
      expect(u.inspect).to eq("UninterpretedSort(U)")
      expect(v.inspect).to eq("UninterpretedSort(V)")
    end

    it "is a value object" do
      expect(u).to eq(UninterpretedSort.new("U"))
      expect(u).to_not eq(v)
    end

    it "can instantiate variables" do
      expect(u.var("a").inspect).to eq("U<a>")
    end

    # Z3 symbols are either strings or integers
    it "can be named by an Integer" do
      expect(UninterpretedSort.new(5).inspect).to eq("UninterpretedSort(5)")
      expect(UninterpretedSort.new(5)).to eq(UninterpretedSort.new(5))
      expect(UninterpretedSort.new(5)).to_not eq(UninterpretedSort.new(6))
    end

    it "elements have no interpretation, they can only be equal or distinct" do
      a, b, c = u.var("a"), u.var("b"), u.var("c")
      expect([a != b, b != c, a != c]).to have_solution(a => "U!val!0", b => "U!val!1", c => "U!val!2")
      expect([a != b, b != c, a == c, a != c]).to have_no_solution
    end

    # Which is what makes them worth having - an uninterpreted function gives the
    # elements the only structure they will ever have
    describe "with uninterpreted functions" do
      let(:age) { Z3.Function("age", u, IntSort.new) }
      let(:alice) { u.var("alice") }
      let(:bob) { u.var("bob") }

      it "can be a function's domain" do
        expect(age.domain(0)).to eq(u)
        expect(age[alice].sort).to eq(IntSort.new)
        expect(age[alice]).to stringify("age(alice)")
      end

      it "constrains its elements through the function" do
        expect([age[alice] == 30, age[bob] == 40, alice == bob]).to have_no_solution
        expect([age[alice] == 30, age[bob] == 30]).to have_solution({})
      end

      # Distinct elements need not have distinct ages, and equal ages need not mean
      # equal elements - only congruence the other way round is forced
      it "is not injective unless you say so" do
        solver = Solver.new
        solver.assert alice != bob
        solver.assert age[alice] == age[bob]
        expect(solver).to be_satisfiable
      end

      it "the model reports both the universe and the function over it" do
        solver = Solver.new
        solver.assert age[alice] == 30
        solver.assert age[bob] == 40
        expect(solver).to be_satisfiable
        model = solver.model
        expect(model.sorts).to eq([u])
        expect(model.sort_universe(u).size).to eq(2)
        expect(model.func_interp(age).default).to be_a(IntExpr)
        expect(model.model_eval(age[alice], true)).to stringify("30")
        expect(model.model_eval(age[bob], true)).to stringify("40")
      end
    end
  end
end
