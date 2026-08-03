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

    describe "#empty?" do
      it "sexpr" do
        expect(xs.empty?.sexpr).to eq("(= (seq.len xs) 0)")
      end

      it "constrains the solution" do
        expect([xs.empty?]).to have_solution(xs => "[]")
        expect([xs.empty?, xs.length == 1]).to have_no_solution
      end
    end

    describe "#+" do
      it "is concatenation" do
        expect((xs + xs).sexpr).to eq("(seq.++ xs xs)")
        expect(xs + xs).to be_a(SeqExpr)
      end

      it "prints as Ruby" do
        expect(xs + sort.from_const([1])).to stringify("xs + [1]")
      end

      it "constrains the solution" do
        expect([xs + sort.from_const([3]) == sort.from_const([1, 2, 3])]).to have_solution(xs => "[1, 2]")
      end
    end

    describe "#*" do
      it "repeats, like Ruby Array#*" do
        expect((xs * 3).sexpr).to eq("(seq.++ xs xs xs)")
        expect(xs * 1).to be_same_as(xs)
        expect([xs * 2 == sort.from_const([1, 2, 1, 2])]).to have_solution(xs => "[1, 2]")
      end

      # Array#*(String) is #join, which a Seq of arbitrary element sort can't do
      it "raises exception on anything but a non-negative Integer" do
        expect { xs * -1 }.to raise_error(Z3::Exception)
        expect { xs * "," }.to raise_error(Z3::Exception)
      end
    end

    # A Seq reads like a Ruby Array, so `xs[i]` is the element - unlike a String,
    # where `s[i]` is a one character String
    describe "#[]" do
      it "sexpr" do
        expect(xs[2].sexpr).to eq("(seq.nth xs 2)")
        expect(xs[2, 3].sexpr).to eq("(seq.extract xs 2 3)")
        expect(xs[2..4].sexpr).to eq("(seq.extract xs 2 3)")
        expect(xs[2...4].sexpr).to eq("(seq.extract xs 2 2)")
      end

      it "gives an element for an index and a sequence for a range" do
        expect(xs[2]).to be_a(IntExpr)
        expect(xs[2].sort).to eq(IntSort.new)
        expect(xs[2, 3]).to be_a(SeqExpr)
        expect(xs[2, 3].sort).to eq(sort)
      end

      it "prints as Ruby" do
        expect(xs[2]).to stringify("xs[2]")
        expect(xs[2, 3]).to stringify("xs[2, 3]")
      end

      it "indexes" do
        value = sort.from_const([10, 20, 30])
        expect([xs == value, xs[1] == 20]).to have_solution(xs => "[10, 20, 30]")
        expect([xs == value, xs[1] == 99]).to have_no_solution
      end

      it "takes subsequences" do
        value = sort.from_const([10, 20, 30, 40])
        expect([xs == value, xs[1, 2] == sort.from_const([20, 30])]).to have_solution(xs => "[10, 20, 30, 40]")
        expect([xs == value, xs[1..2] == sort.from_const([20, 30])]).to have_solution(xs => "[10, 20, 30, 40]")
        expect([xs == value, xs[1...3] == sort.from_const([20, 30])]).to have_solution(xs => "[10, 20, 30, 40]")
        expect([xs == value, xs[2..] == sort.from_const([30, 40])]).to have_solution(xs => "[10, 20, 30, 40]")
      end

      it "is empty out of range" do
        expect([xs == sort.from_const([10]), xs[5, 2].empty?]).to have_solution(xs => "[10]")
      end

      # An index is an offset however it's spelled, so a literal -1 and an IntExpr
      # equal to -1 have to mean the same thing - which means neither of them counts
      # from the end the way Ruby's Array#[] does. See StringExpr#[] for why.
      it "passes a negative index through as an offset" do
        expect(xs[-1].sexpr).to eq("(seq.nth xs (- 1))")
        expect(xs[-2, 2].sexpr).to eq("(seq.extract xs (- 2) 2)")
      end

      it "means the same by a literal index and a symbolic one" do
        i = IntSort.new.var("i")
        value = sort.from_const([10, 20, 30])
        # An out of range element is unspecified, so both of these are satisfiable
        # with any value at all rather than with the last one
        expect([xs == value, xs[-1] == 99]).to have_solution(xs => "[10, 20, 30]")
        expect([xs == value, i == -1, xs[i] == 99]).to have_solution(xs => "[10, 20, 30]")
        # An out of range subsequence is empty
        expect([xs == value, xs[-2, 2].empty?]).to have_solution(xs => "[10, 20, 30]")
        expect([xs == value, i == -1, xs[i, 2].empty?]).to have_solution(xs => "[10, 20, 30]")
        expect([xs == value, xs[0..-1].empty?]).to have_solution(xs => "[10, 20, 30]")
        expect([xs == value, i == -1, xs[0..i].empty?]).to have_solution(xs => "[10, 20, 30]")
      end

      # Counting from the end is spelled out, and #last is exactly that
      it "counts from the end when told to" do
        value = sort.from_const([10, 20, 30])
        expect([xs == value, xs[xs.length - 1] == 30]).to have_solution(xs => "[10, 20, 30]")
        expect([xs == value, xs[xs.length - 2, 2] == sort.from_const([20, 30])]).to have_solution(xs => "[10, 20, 30]")
      end

      # #at is Ruby Array#at and #slice is Ruby Array#slice - both are #[]
      it "#at and #slice are the same thing" do
        expect(xs.at(2)).to be_same_as(xs[2])
        expect(xs.slice(2)).to be_same_as(xs[2])
        expect(xs.slice(1, 2)).to be_same_as(xs[1, 2])
      end

      it "takes symbolic indices" do
        i = IntSort.new.var("i")
        expect([xs == sort.from_const([10, 20, 30]), xs[i] == 30, i == 2]).to have_solution(xs => "[10, 20, 30]")
      end
    end

    describe "#first and #last" do
      it "sexpr" do
        expect(xs.first.sexpr).to eq("(seq.nth xs 0)")
        expect(xs.last.sexpr).to eq("(seq.nth xs (- (seq.len xs) 1))")
        expect(xs.first(2).sexpr).to eq("(seq.extract xs 0 2)")
        expect(xs.last(2).sexpr).to eq("(seq.extract xs (- (seq.len xs) 2) 2)")
      end

      it "constrains the solution" do
        value = sort.from_const([10, 20, 30])
        expect([xs == value, xs.first == 10, xs.last == 30]).to have_solution(xs => "[10, 20, 30]")
        expect([xs == value, xs.first(2) == sort.from_const([10, 20])]).to have_solution(xs => "[10, 20, 30]")
        expect([xs == value, xs.last(2) == sort.from_const([20, 30])]).to have_solution(xs => "[10, 20, 30]")
      end
    end

    # Z3 takes a subsequence everywhere Ruby's Array takes an element, so a bare
    # element gets wrapped and a Ruby Array or a Seq of this sort doesn't
    describe "#include?" do
      it "wraps a bare element into a one element sequence" do
        expect(xs.include?(7).sexpr).to eq("(seq.contains xs (seq.unit 7))")
        expect(xs.include?([1, 2]).sexpr).to eq("(seq.contains xs (seq.++ (seq.unit 1) (seq.unit 2)))")
        expect(xs.include?(sort.from_const([1, 2]))).to be_same_as(xs.include?([1, 2]))
      end

      it "prints as Ruby that means the same thing when read back" do
        expect(xs.include?(7)).to stringify("xs.include?(7)")
      end

      it "constrains the solution" do
        value = sort.from_const([10, 20, 30])
        expect([xs == value, xs.include?(20)]).to have_solution(xs => "[10, 20, 30]")
        expect([xs == value, xs.include?(99)]).to have_no_solution
        expect([xs == value, xs.include?([20, 30])]).to have_solution(xs => "[10, 20, 30]")
        expect([xs == value, xs.include?([10, 30])]).to have_no_solution
      end

      # A Seq of Seq has no ambiguity to resolve: an element is a Seq(Int), which is a
      # different sort from the Seq(Seq(Int)) a subsequence would be
      it "still wraps when the element sort is itself a sequence" do
        nested = SeqSort.new(sort).var("nested")
        expect(nested.include?(sort.from_const([1])).sexpr).to eq("(seq.contains nested (seq.unit (seq.unit 1)))")
      end
    end

    describe "#start_with? and #end_with?" do
      it "sexpr, with Z3's arguments the other way round" do
        expect(xs.start_with?(7).sexpr).to eq("(seq.prefixof (seq.unit 7) xs)")
        expect(xs.end_with?([1, 2]).sexpr).to eq("(seq.suffixof (seq.++ (seq.unit 1) (seq.unit 2)) xs)")
      end

      it "prints as Ruby, with the receiver back in front" do
        expect(xs.start_with?(7)).to stringify("xs.start_with?(7)")
      end

      it "constrains the solution" do
        value = sort.from_const([10, 20, 30])
        expect([xs == value, xs.start_with?(10)]).to have_solution(xs => "[10, 20, 30]")
        expect([xs == value, xs.start_with?(20)]).to have_no_solution
        expect([xs == value, xs.end_with?([20, 30])]).to have_solution(xs => "[10, 20, 30]")
        expect([xs == value, xs.end_with?(10)]).to have_no_solution
        expect([xs == value, xs.start_with?(99, 10)]).to have_solution(xs => "[10, 20, 30]")
      end
    end

    describe "#index" do
      it "sexpr" do
        expect(xs.index(7).sexpr).to eq("(seq.indexof xs (seq.unit 7) 0)")
        expect(xs.index(7, 2).sexpr).to eq("(seq.indexof xs (seq.unit 7) 2)")
      end

      it "prints as Ruby" do
        expect(xs.index(7)).to stringify("xs.index(7)")
      end

      it "constrains the solution" do
        value = sort.from_const([10, 20, 10])
        expect([xs == value, xs.index(10) == 0]).to have_solution(xs => "[10, 20, 10]")
        expect([xs == value, xs.index(10, 1) == 2]).to have_solution(xs => "[10, 20, 10]")
        expect([xs == value, xs.index(99) == -1]).to have_solution(xs => "[10, 20, 10]")
      end
    end

    # `seq.last_indexof` builds fine and works for Strings, but Z3 4.16 answers an
    # out of range value for every sequence of non-characters, so there's nothing
    # about the result worth asserting yet
    describe "#rindex" do
      it "sexpr" do
        expect(xs.rindex(7).sexpr).to eq("(seq.last_indexof xs (seq.unit 7))")
      end

      it "prints as Ruby" do
        expect(xs.rindex(7)).to stringify("xs.rindex(7)")
      end
    end

    describe "#sub and #gsub" do
      # Ruby's Array has nothing like these, so they keep String's names
      it "sexpr" do
        expect(xs.sub(1, 2).sexpr).to eq("(seq.replace xs (seq.unit 1) (seq.unit 2))")
        # Z3 calls this one `str.replace_all` even for sequences of non-characters
        expect(xs.gsub(1, 2).sexpr).to eq("(str.replace_all xs (seq.unit 1) (seq.unit 2))")
      end

      it "prints as Ruby" do
        expect(xs.sub(1, 2)).to stringify("xs.sub(1, 2)")
        expect(xs.gsub(1, 2)).to stringify("xs.gsub(1, 2)")
      end

      it "replaces the first occurrence, or all of them" do
        value = sort.from_const([1, 2, 1])
        expect([xs == value, xs.sub(1, 9) == sort.from_const([9, 2, 1])]).to have_solution(xs => "[1, 2, 1]")
        expect([xs == value, xs.gsub(1, 9) == sort.from_const([9, 2, 9])]).to have_solution(xs => "[1, 2, 1]")
      end
    end

    describe ".Unit" do
      it "is a one element sequence" do
        expect(SeqExpr.Unit(IntSort.new.from_const(1)).sexpr).to eq("(seq.unit 1)")
        expect(SeqExpr.Unit(IntSort.new.from_const(1)).sort).to eq(sort)
      end

      # Z3 models a String as a Seq(Char), so a unit Char is a one character String
      it "of a Char is a String" do
        expect(SeqExpr.Unit(CharSort.new.from_const("a"))).to be_a(StringExpr)
      end
    end

    describe ".Concat" do
      it "concatenates any number of sequences" do
        expect(SeqExpr.Concat(xs, xs, xs).sexpr).to eq("(seq.++ xs xs xs)")
        # Z3 rejects a concatenation of fewer than two sequences
        expect(SeqExpr.Concat(xs)).to be_same_as(xs)
        expect { SeqExpr.Concat }.to raise_error(Z3::Exception)
      end
    end

    describe "raises exception on sort mismatch" do
      it "for the element sort" do
        expect { xs.include?("a") }.to raise_error(Z3::Exception)
        expect { xs[0] == "a" }.to raise_error(ArgumentError)
        expect { xs + SeqSort.new(BoolSort.new).var("bs") }.to raise_error(ArgumentError)
      end
    end
  end
end
