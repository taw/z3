module Z3
  describe StringExpr do
    let(:sort) { StringSort.new }
    let(:s) { sort.var("s") }

    describe "#length" do
      it "is an IntExpr" do
        expect(s.length).to be_a(IntExpr)
        expect(s.length.sort).to eq(IntSort.new)
      end

      # Z3 calls it `str.len` for strings and `seq.len` for other sequences,
      # even though it's one operation
      it "sexpr" do
        expect(s.length.sexpr).to eq("(str.len s)")
        expect(sort.from_const("hello").length.sexpr).to eq(%q{(str.len "hello")})
      end

      it "prints as a Ruby method call" do
        expect(s.length).to stringify("s.size")
        expect(sort.from_const("hello").length).to stringify(%q{"hello".size})
      end

      it "#size is the same thing" do
        expect(s.size).to be_same_as(s.length)
      end

      it "evaluates in a model" do
        solver = Solver.new
        solver.assert s == "héllo"
        expect(solver).to be_satisfiable
        expect(solver.model.model_eval(s.length).to_s).to eq("5")
      end

      it "constrains the solution" do
        expect([s.length == 5, s == "hello"]).to have_solution(s => %q{"hello"})
        expect([s.length == 5, s == "abc"]).to have_no_solution
      end

      # It's an ordinary IntExpr, so all of ArithExpr works on it
      it "does arithmetic" do
        expect([s.length + 1 == 4, s == "abc"]).to have_solution(s => %q{"abc"})
        expect([s.length >= 2, s.length <= 2, s == "ab"]).to have_solution(s => %q{"ab"})
      end

      it "is zero for the empty string" do
        solver = Solver.new
        solver.assert s == ""
        expect(solver).to be_satisfiable
        expect(solver.model.model_eval(s.length).to_s).to eq("0")
      end
    end
  end
end
