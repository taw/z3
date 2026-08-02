module Z3
  describe SeqExpr do
    let(:sort) { SeqSort.new(IntSort.new) }
    let(:xs) { sort.var("xs") }

    it "#element_sort" do
      expect(xs.element_sort).to eq(IntSort.new)
      expect(SeqSort.new(StringSort.new).var("q").element_sort).to eq(StringSort.new)
      expect(SeqSort.new(sort).var("q").element_sort).to eq(sort)
    end

    describe "#length" do
      it "is an IntExpr" do
        expect(xs.length).to be_a(IntExpr)
        expect(xs.length.sort).to eq(IntSort.new)
      end

      # `seq.len` and String's `str.len` are one Z3 operation with two names
      it "sexpr" do
        expect(xs.length.sexpr).to eq("(seq.len xs)")
      end

      it "prints as a Ruby method call" do
        expect(xs.length).to stringify("xs.size")
      end

      it "#size is the same thing" do
        expect(xs.size).to be_same_as(xs.length)
      end

      it "evaluates in a model" do
        solver = Solver.new
        solver.assert xs == sort.from_const([1, 2, 3])
        expect(solver).to be_satisfiable
        expect(solver.model.model_eval(xs.length).to_s).to eq("3")
      end

      it "constrains the solution" do
        expect([xs.length == 3, xs == sort.from_const([1, 2, 3])]).to have_solution(xs => "[1, 2, 3]")
        expect([xs.length == 3, xs == sort.from_const([1, 2])]).to have_no_solution
      end

      it "is zero for the empty sequence" do
        solver = Solver.new
        solver.assert xs == sort.from_const([])
        expect(solver).to be_satisfiable
        expect(solver.model.model_eval(xs.length).to_s).to eq("0")
      end

      # Sequences of anything, not just Int
      it "works for other element sorts" do
        bools = SeqSort.new(BoolSort.new).var("bs")
        expect(bools.length.sexpr).to eq("(seq.len bs)")
      end
    end
  end
end
