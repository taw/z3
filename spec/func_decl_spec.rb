module Z3
  describe FuncDecl do
    let(:int) { IntSort.new }
    let(:bool) { BoolSort.new }
    let(:f) { Z3.Function("f", int, int) }
    let(:plus) { Z3.Function("plus", int, int, int) }
    let(:x) { Z3.Int("x") }
    let(:y) { Z3.Int("y") }

    # An indexed decl carries its indices as parameters rather than in its name -
    # `(_ extract 7 0)` and `(_ extract 3 2)` are both called "extract", so the
    # parameters are the only place the 7 and the 0 exist
    describe "#parameter" do
      let(:bv) { Z3.Bitvec("bv", 16) }

      it "reads Integer parameters" do
        extract = bv.extract(7, 0).func_decl
        expect(extract.name).to eq("extract")
        expect(extract.num_parameters).to eq(2)
        expect(extract.parameter(0)).to eq(7)
        expect(extract.parameter(1)).to eq(0)

        expect(bv.zero_ext(8).func_decl.parameter(0)).to eq(8)
        expect(bv.rotate_left(3).func_decl.parameter(0)).to eq(3)
        expect(x.to_bv(8).func_decl.parameter(0)).to eq(8)
        # A Char literal is `(_ Char 97)`, so the code point is a parameter
        expect(CharSort.new.from_const("a").func_decl.parameter(0)).to eq(97)
      end

      # Set values come back from a model as `((as const (Array Int Bool)) false)`
      it "reads Sort parameters" do
        solver = Solver.new
        solver.assert SetSort.new(int).var("a").complement.include?(3)
        expect(solver.check).to eq(:sat)
        decl = solver.model.each.first[1].func_decl
        expect(decl.parameter_kind(0)).to eq(:sort)
        expect(decl.parameter(0)).to eq(SetSort.new(int))
      end

      # Enum recognizers are `(_ is red)` - every one of them is named "is", and which
      # value it tests for is a parameter
      it "reads FuncDecl parameters" do
        sort = EnumSort.new("ParameterDemo", %i[red green])
        recognizer = FuncDecl.new(LowLevel.get_datatype_sort_recognizer(sort, 0))
        expect(recognizer.name).to eq("is")
        expect(recognizer.parameter(0)).to eq(recognizer.func_decl_parameter(0))
        expect(recognizer.parameter(0).name).to eq("red")
      end

      # Two of the nine kinds have nothing behind them: Z3 has no
      # `get_decl_zstring_parameter` at all, and `:internal` is opaque by definition
      it "raises for the kinds Z3 won't hand back" do
        expect{ StringSort.new.from_const("abc").func_decl.parameter(0) }
          .to raise_error(Z3::Exception, /\AParameter 0 is a string, and Z3 offers no way to read one back/)
        expect{ FloatSort.new(11, 53).from_const(2.5).func_decl.parameter(0) }
          .to raise_error(Z3::Exception, "Parameter 0 is internal, which Z3 keeps to itself")
      end

      it "raises for an index which isn't there" do
        expect{ bv.extract(7, 0).func_decl.parameter(2) }
          .to raise_error(Z3::Exception, "Trying to access parameter 2 but decl has 2 parameters")
        expect{ bv.extract(7, 0).func_decl.parameter(-1) }
          .to raise_error(Z3::Exception, "Trying to access parameter -1 but decl has 2 parameters")
        expect{ (x + 1).func_decl.parameter(0) }
          .to raise_error(Z3::Exception, "Trying to access parameter 0 but decl has 0 parameters")
      end

      # :double, :rational and :symbol are implemented by the book, but nothing this
      # gem can build produces a decl carrying one, so they go untested
      it "covers every parameter kind which has a producer here" do
        expect(FuncDecl::PARAMETER_KINDS.values)
          .to match_array(%i[int double rational symbol sort ast func_decl internal zstring])
      end
    end

    describe "Z3.Function" do
      # Z3 hash-conses them, so redeclaring is the same function, not a second one
      it "is a value object" do
        expect(Z3.Function("f", int, int)).to eq(f)
        expect(Z3.Function("f", int, int).hash).to eq(f.hash)
        expect(Z3.Function("other", int, int)).to_not eq(f)
        # Same name, different signature is a different function
        expect(Z3.Function("f", int, bool)).to_not eq(f)
      end

      it "declares a function, last sort being the range" do
        expect(f).to be_a(FuncDecl)
        expect(f.name).to eq("f")
        expect(f.arity).to eq(1)
        expect(f.domain(0)).to eq(int)
        expect(f.range).to eq(int)
      end

      it "takes any number of argument sorts" do
        expect(plus.arity).to eq(2)
        expect(plus.domain(0)).to eq(int)
        expect(plus.domain(1)).to eq(int)
        expect(plus.range).to eq(int)
        constant = Z3.Function("c", int)
        expect(constant.arity).to eq(0)
        expect(constant.range).to eq(int)
      end

      it "takes a Symbol name too" do
        expect(Z3.Function(:g, int, int).name).to eq("g")
      end

      it "raises unless given sorts" do
        expect{ Z3.Function("f") }.to raise_error(Z3::Exception, "Function needs at least a range sort")
        expect{ Z3.Function("f", int, 42) }.to raise_error(Z3::Exception, "Sort expected, got Integer")
        expect{ Z3.Function("f", int, nil) }.to raise_error(Z3::Exception, "Sort expected, got nil")
      end
    end

    # A recursive function *is* its body, where an uninterpreted function is only
    # constrained by whatever was asserted about it. Every example declares its own
    # name, because Z3 hash-conses declarations - two "fact"s of the same signature
    # are one declaration, and it would be defined twice.
    describe "Z3.RecFunction" do
      it "defines a function by its own body" do
        fact = Z3.RecFunction("fact", int, int) { |fact, n| Z3.IfThenElse(n <= 0, 1, n * fact[n - 1]) }
        expect(fact).to be_a(FuncDecl)
        expect(fact.name).to eq("fact")
        expect(fact.arity).to eq(1)
        expect([fact[5] == x]).to have_solution(x => 120)
      end

      it "knows what the function isn't" do
        fact = Z3.RecFunction("fact_unsat", int, int) { |fact, n| Z3.IfThenElse(n <= 0, 1, n * fact[n - 1]) }
        expect([fact[5] == 100]).to have_no_solution
      end

      it "takes several arguments" do
        add = Z3.RecFunction("slow_add", int, int, int) { |add, a, b| Z3.IfThenElse(b <= 0, a, add[a + 1, b - 1]) }
        expect([add[3, 4] == x]).to have_solution(x => 7)
      end

      it "can have a Bool range" do
        pos = Z3.RecFunction("all_pos_down_to_zero", int, bool) { |pos, n| Z3.IfThenElse(n <= 0, true, pos[n - 1]) }
        expect([pos[3]]).to have_solution({})
      end

      # Without a block the declaration comes back undefined, which is what mutually
      # recursive functions need - each body mentions a function declared separately
      it "defines mutually recursive functions in two steps" do
        even = Z3.RecFunction("even", int, bool)
        odd = Z3.RecFunction("odd", int, bool)
        expect(even.define { |n| Z3.IfThenElse(n == 0, true, odd[n - 1]) }).to eq(even)
        odd.define { |n| Z3.IfThenElse(n == 0, false, even[n - 1]) }

        expect([even[10], odd[7]]).to have_solution({})
        expect([even[7]]).to have_no_solution
        expect([odd[10]]).to have_no_solution
      end

      it "evaluates in a model" do
        fib = Z3.RecFunction("fib", int, int) { |fib, n| Z3.IfThenElse(n <= 1, n, fib[n - 1] + fib[n - 2]) }
        solver = Solver.new
        solver.assert x == 10
        expect(solver.check).to eq(:sat)
        expect(solver.model.model_eval(fib[x], true).to_i).to eq(55)
      end

      it "is an ordinary declaration otherwise" do
        double = Z3.RecFunction("double", int, int) { |_, n| n * 2 }
        expect(double.domain(0)).to eq(int)
        expect(double.range).to eq(int)
        expect(double[x]).to be_a(IntExpr)
        expect(double.to_s).to eq("double")
      end

      it "knows itself apart from an ordinary declaration" do
        rec = Z3.RecFunction("recursive_p", int, int) { |_, n| n }
        expect(rec).to be_recursive
        expect(Z3.Function("recursive_p_not", int, int)).to_not be_recursive
        # An undefined one is recursive too - it's the declaration that decides
        expect(Z3.RecFunction("recursive_p_undefined", int, int)).to be_recursive
      end

      # A definition belongs to the context, not to the solver that first saw it -
      # the same as `define-fun-rec` in an SMT-LIB script. Z3 then hands it back in
      # every model it builds afterwards, of every solver, whether or not the query
      # mentioned it, and its `else` branch is a body over de Bruijn variables which
      # no Expr can hold - so Model#funcs leaves recursive definitions out.
      it "is context-global, and left out of models" do
        f = Z3.Function("uninterpreted_beside_rec", int, int)
        Z3.RecFunction("in_every_model", int, int) { |_, n| n * 2 }
        solver = Solver.new
        solver.assert f[1] == 10
        expect(solver.check).to eq(:sat)
        expect(solver.model.funcs.map(&:name)).to eq(["uninterpreted_beside_rec"])
        expect(solver.model.num_funcs).to eq(1)
        expect { solver.model.to_s }.to_not raise_error
      end

      it "refuses to define a function which wasn't declared recursive" do
        expect {
          Z3.Function("not_rec", int, int).define { |n| n + 1 }
        }.to raise_error(Z3::Exception, /needs to be declared using rec_func_decl/)
      end
    end

    describe "Z3.FreshFunction" do
      # The number Z3 appends comes from a counter shared by the whole context -
      # shared across prefixes, and with mk_fresh_const too - so which one this gets
      # depends on every other example that ran first. Nothing here may assert it.
      it "names itself after the prefix" do
        expect(Z3.FreshFunction("f", int, int).name).to start_with("f")
        expect(Z3.FreshFunction("helper", int, int).name).to start_with("helper")
      end

      it "picks a different name every time" do
        names = 3.times.map { Z3.FreshFunction("f", int, int).name }
        expect(names.uniq.size).to eq(3)
      end

      it "has the signature it was given" do
        f = Z3.FreshFunction("f", int, bool)
        expect(f.arity).to eq(1)
        expect(f.domain(0)).to eq(int)
        expect(f.range).to eq(bool)
        expect(Z3.FreshFunction("k", int).arity).to eq(0)
      end

      # The point of it - two of these are genuinely unrelated functions, where two
      # Z3.Function calls with one name would be the same function twice
      it "is a different function each time, not just a different name" do
        a = Z3.FreshFunction("f", int, int)
        b = Z3.FreshFunction("f", int, int)
        expect([a[1] == 1, b[1] == 2]).to have_solution({})
        named = Z3.Function("same", int, int)
        expect([named[1] == 1, Z3.Function("same", int, int)[1] == 2]).to have_no_solution
      end

      it "rejects a bad signature the same way Z3.Function does" do
        expect{ Z3.FreshFunction("f") }.to raise_error(Z3::Exception, "Function needs at least a range sort")
        expect{ Z3.FreshFunction("f", int, 42) }.to raise_error(Z3::Exception, "Sort expected, got Integer")
      end

      # "Fresh" means unused as of now, not reserved - worth knowing before relying
      # on it for anything but convenience
      it "does not reserve the name against a later declaration" do
        fresh = Z3.FreshFunction("f", int, int)
        expect(Z3.Function(fresh.name, int, int)).to eq(fresh)
      end
    end

    describe "#[]" do
      it "applies the function" do
        expect(f[x]).to stringify("f(x)")
        expect(f[x].sort).to eq(int)
        expect(plus[x, y]).to stringify("plus(x, y)")
      end

      it "casts arguments to the declared domain" do
        expect(f[3]).to stringify("f(3)")
        expect(Z3.Function("g", RealSort.new, int)[1]).to stringify("g(1)")
      end

      it "composes like any other expression" do
        expect(f[f[x]] + 1).to stringify("f(f(x)) + 1")
        expect(Z3.Function("p", int, bool)[x].sort).to eq(bool)
      end

      it "#call is the same thing" do
        expect(f.call(x)).to be_same_as(f[x])
      end

      it "raises on the wrong number of arguments" do
        expect{ f[] }.to raise_error(Z3::Exception, "f takes 1 argument, got 0")
        expect{ f[1, 2] }.to raise_error(Z3::Exception, "f takes 1 argument, got 2")
        expect{ plus[1] }.to raise_error(Z3::Exception, "plus takes 2 arguments, got 1")
      end

      it "raises on arguments of the wrong sort" do
        expect{ f[true] }.to raise_error(Z3::Exception, "Can't convert true into Int")
        expect{ f[Z3.Bool("b")] }.to raise_error(Z3::Exception, "Can't convert Bool into Int")
      end
    end

    describe "solving" do
      # The one every Z3 tutorial opens with
      it "f(f(x)) == x with f(x) == y and x != y" do
        solver = Solver.new
        solver.assert f[f[x]] == x
        solver.assert f[x] == y
        solver.assert x != y
        expect(solver).to be_satisfiable
      end

      it "is uninterpreted, so only the asserted constraints hold" do
        expect([f[1] == 10, f[2] == 20, f[1] == 11]).to have_no_solution
        expect([f[1] == 10, f[2] == 20]).to have_solution({})
      end

      # Congruence: equal arguments have to give equal results
      it "respects congruence" do
        expect([x == y, f[x] != f[y]]).to have_no_solution
        expect([f[x] != f[y], x == y]).to have_no_solution
      end

      it "works with a Bool range as a predicate" do
        likes = Z3.Function("likes", int, int, bool)
        solver = Solver.new
        solver.assert likes[1, 2]
        solver.assert ~likes[2, 1]
        expect(solver).to be_satisfiable
      end

      it "works over an uninterpreted sort" do
        person = UninterpretedSort.new("Person")
        age = Z3.Function("age", person, int)
        alice = person.var("alice")
        bob = person.var("bob")
        solver = Solver.new
        solver.assert age[alice] > age[bob]
        solver.assert age[bob] == 30
        expect(solver).to be_satisfiable
        expect(solver.model.model_eval(age[alice], true).to_i).to be > 30
      end
    end
  end
end
