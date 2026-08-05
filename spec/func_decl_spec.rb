module Z3
  describe FuncDecl do
    let(:int) { IntSort.new }
    let(:bool) { BoolSort.new }
    let(:f) { Z3.Function("f", int, int) }
    let(:plus) { Z3.Function("plus", int, int, int) }
    let(:x) { Z3.Int("x") }
    let(:y) { Z3.Int("y") }

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
