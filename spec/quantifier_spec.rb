module Z3
  describe "quantifiers" do
    let(:int) { IntSort.new }
    let(:x) { Z3.Int("x") }
    let(:y) { Z3.Int("y") }
    let(:f) { Z3.Function("f", int, int) }
    let(:g) { Z3.Function("g", int, int, int) }

    # Z3's own `_const` constructors take the variables you already have rather than
    # de Bruijn indices, so nothing here has to know about those
    describe "Z3.ForAll" do
      it "binds one variable" do
        expect(Z3.ForAll(x, f[x] > 0).sexpr).to eq("(forall ((x Int)) (> (f x) 0))")
      end

      it "binds several" do
        expect(Z3.ForAll([x, y], g[x, y] == g[y, x]).sexpr)
          .to eq("(forall ((x Int) (y Int)) (= (g x y) (g y x)))")
      end

      it "is a Bool" do
        expect(Z3.ForAll(x, f[x] > 0)).to be_a BoolExpr
        expect(Z3.ForAll(x, f[x] > 0).sort).to eq(BoolSort.new)
      end

      it "casts a Ruby body" do
        expect(Z3.ForAll(x, true).sexpr).to eq("(forall ((x Int)) true)")
      end

      it "solves" do
        expect([Z3.ForAll(x, f[x] > 0), f[3] == 0]).to have_no_solution

        solver = Solver.new
        solver.assert Z3.ForAll(x, f[x] > 0)
        solver.assert f[3] == 5
        expect(solver).to be_satisfiable

        solver = Solver.new
        solver.assert Z3.ForAll(x, f[x] == x + 1)
        solver.assert f[2] != 3
        expect(solver).to_not be_satisfiable
      end
    end

    describe "Z3.Exists" do
      it "binds variables" do
        expect(Z3.Exists(x, f[x] == 99).sexpr).to eq("(exists ((x Int)) (= (f x) 99))")
      end

      it "solves" do
        solver = Solver.new
        solver.assert Z3.Exists(x, f[x] == 99)
        expect(solver).to be_satisfiable

        # No x has f(x) both 1 and 2
        expect([Z3.ForAll(x, f[x] == 1), Z3.Exists(x, f[x] == 2)]).to have_no_solution
      end
    end

    # A lambda is an Array to Z3, so it indexes with the `[]` ArrayExpr already has
    describe "Z3.Lambda" do
      let(:double) { Z3.Lambda(x, x * 2) }

      it "is an Array" do
        expect(double).to be_a ArrayExpr
        expect(double.sort).to eq(ArraySort.new(int, int))
        expect(double.sexpr).to eq("(lambda ((x Int)) (* x 2))")
      end

      it "applies with []" do
        expect([double[3] != 6]).to have_no_solution
        expect([double[3] == 6, double[5] == 10]).to have_solution({})
        expect([double[5] == 11]).to have_no_solution
      end

      it "takes the value sort from the body" do
        expect(Z3.Lambda(x, x > 2).sort).to eq(SetSort.new(int))
        expect(Z3.Lambda(x, 5).sort).to eq(ArraySort.new(int, int))
      end

      # Two would be an Array(Int, Int, Int), and there's no sort here for those -
      # Sort.from_pointer would report Array(Int, Int) and indexing would fail in Z3
      it "takes exactly one bound variable" do
        expect{ Z3.Lambda([x, y], x + y) }
          .to raise_error(Z3::Exception, "Lambda takes one bound variable, got 2")
      end
    end

    describe "bound variables" do
      it "have to be variables" do
        expect{ Z3.ForAll(x + 1, f[x] > 0) }
          .to raise_error(Z3::Exception, "Bound variables must be variables, got Int")
        expect{ Z3.ForAll(int.from_const(3), f[3] > 0) }
          .to raise_error(Z3::Exception, "Bound variables must be variables, got Int")
        expect{ Z3.ForAll(3, f[3] > 0) }
          .to raise_error(Z3::Exception, "Bound variables must be variables, got Integer")
      end

      it "need at least one" do
        expect{ Z3.ForAll([], f[3] > 0) }
          .to raise_error(Z3::Exception, "Quantifier needs at least one bound variable")
      end

      # Z3 takes a repeat and renames the second to `x!1`, shadowing the first
      it "have to be distinct" do
        expect{ Z3.ForAll([x, x], f[x] > 0) }
          .to raise_error(Z3::Exception, "Bound variables must be distinct")
      end

      it "leave the outer variable alone" do
        quantified = Z3.ForAll(x, f[x] > 0)
        solver = Solver.new
        solver.assert quantified
        solver.assert x == -5
        expect(solver).to be_satisfiable
        expect(solver.model[x].to_i).to eq(-5)
      end
    end

    # The body has de Bruijn indices substituted in, and `:var` is an AST kind Expr
    # refuses - so this is deliberately not exposed, and the printer falls back to
    # SMT-LIB for a quantifier rather than descending into it
    it "prints as SMT-LIB rather than raising" do
      quantified = Z3.ForAll(x, f[x] > 0)
      expect(quantified.to_s).to eq("(forall ((x Int)) (> (f x) 0))")
      expect(quantified.inspect).to eq("Bool<(forall ((x Int)) (> (f x) 0))>")
      expect{ Expr.new_from_pointer(LowLevel.get_quantifier_body(quantified)).to_s }
        .to raise_error(Z3::Exception, "Values must have AST kind numeral, app, or quantifier")
    end

    # Weight is an instantiation hint, not part of the meaning, but a bad one turns a
    # decidable problem into :unknown - so it's pinned at the value SMT-LIB parsing
    # gives, and the two agree
    it "uses the same weight as parsing the formula from SMT-LIB" do
      built = Z3.ForAll(x, f[x] > 0)
      parsed = Solver.new.tap { |s|
        s.from_string("(declare-fun f (Int) Int)(assert (forall ((x Int)) (> (f x) 0)))")
      }.assertions.first
      expect(LowLevel.get_quantifier_weight(built)).to eq(1)
      expect(LowLevel.get_quantifier_weight(built)).to eq(LowLevel.get_quantifier_weight(parsed))
      expect(built.sexpr).to eq(parsed.sexpr)
    end
  end
end
