module Z3
  describe SeqExpr do
    let(:sort) { SeqSort.new(IntSort.new) }
    let(:xs) { sort.var("xs") }
    let(:ys) { sort.var("ys") }
    let(:n) { Z3.Int("n") }

    # Pins the sequence down, then reads the term back out of the model - everything
    # the map and fold groups check is a value rather than a printed term
    def value_of(term, *assertions)
      solver = Solver.new
      assertions.each { |a| solver.assert a }
      raise "unsat" unless solver.satisfiable?
      solver.model[term].value
    end

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
        # An out of range subsequence is empty, and that one does have a value to read
        expect([xs == value, ys == xs[-2, 2]]).to have_solution(ys => "[]")
        expect([xs == value, i == -1, ys == xs[i, 2]]).to have_solution(ys => "[]")
        expect([xs == value, ys == xs[0..-1]]).to have_solution(ys => "[]")
        expect([xs == value, i == -1, ys == xs[0..i]]).to have_solution(ys => "[]")
      end

      # Counting from the end is spelled out, and #last is exactly that
      it "counts from the end when told to" do
        value = sort.from_const([10, 20, 30])
        expect([xs == value, n == xs[xs.length - 1]]).to have_solution(n => "30")
        expect([xs == value, ys == xs[xs.length - 2, 2]]).to have_solution(ys => "[20, 30]")
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

      # Both ends of a Range can be symbolic too, open ends included
      it "takes symbolic ranges" do
        i = IntSort.new.var("i")
        j = IntSort.new.var("j")
        value = sort.from_const([10, 20, 30, 40])
        expect([xs == value, i == 1, j == 2, ys == xs[i..j]]).to have_solution(ys => "[20, 30]")
        expect([xs == value, i == 1, j == 3, ys == xs[i...j]]).to have_solution(ys => "[20, 30]")
        expect([xs == value, i == 2, ys == xs[i..]]).to have_solution(ys => "[30, 40]")
        expect([xs == value, i == 1, ys == xs[..i]]).to have_solution(ys => "[10, 20]")
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

      # A ReExpr is the one argument here that isn't read as an element-or-subsequence.
      # Z3 4.16 builds these terms but neither solves nor simplifies them.
      it "takes a Re pattern" do
        re = Re.Of([1], sort)
        expect(xs.sub(re, 9).sexpr).to eq("(str.replace_re xs (seq.to.re (seq.unit 1)) (seq.unit 9))")
        expect(xs.gsub(re, 9).sexpr).to eq("(str.replace_re_all xs (seq.to.re (seq.unit 1)) (seq.unit 9))")
        expect(xs.sub(re, 9).sort).to eq(sort)
      end
    end

    describe "#matches?" do
      it "sexpr" do
        expect(xs.matches?(Re.Of([1], sort)).sexpr).to eq("(seq.in.re xs (seq.to.re (seq.unit 1)))")
      end

      it "prints as Ruby" do
        expect(xs.matches?(Re.Of([1], sort))).to stringify("xs.matches?(Re.Of([1]))")
      end

      it "matches the whole sequence" do
        expect([xs.matches?(Re.Of([1], sort).plus), xs == sort.from_const([1, 1])]).to have_solution(xs => "[1, 1]")
        expect([xs.matches?(Re.Of([1], sort).plus), xs == sort.from_const([1, 2])]).to have_no_solution
      end

      # Same rule as StringExpr#matches? - a sequence is never silently a regex here
      it "does not convert its argument" do
        expect { xs.matches?([1]) }.to raise_error(Z3::Exception)
        expect { xs.matches?(Re.Of("a")) }.to raise_error(Z3::Exception)
      end
    end

    describe "#value" do
      it "gives a Ruby Array back, the way StringExpr#value gives a Ruby String" do
        expect(sort.from_const([]).value).to eq([])
        expect(sort.from_const([1]).value).to eq([1])
        expect(sort.from_const([1, 2, 3]).value).to eq([1, 2, 3])
      end

      # Z3 has no sequence literal - a value is a concatenation of one element
      # sequences, and models nest those any which way
      it "walks a concatenation however it's nested" do
        expect((sort.from_const([1, 2]) + sort.from_const([3])).value).to eq([1, 2, 3])
        expect((sort.from_const([]) + sort.from_const([1])).value).to eq([1])
        expect(SeqExpr.Concat(sort.from_const([1]), sort.from_const([2]), sort.from_const([3])).value).to eq([1, 2, 3])
      end

      it "simplifies first, like StringExpr#value does" do
        expect((sort.from_const([1, 2, 3]) * 2).value).to eq([1, 2, 3, 1, 2, 3])
        expect(sort.from_const([1, 2, 3])[1, 2].value).to eq([2, 3])
      end

      it "calls #value on the elements, so nesting works" do
        expect(SeqSort.new(sort).from_const([[1], [2, 3]]).value).to eq([[1], [2, 3]])
        expect(SeqSort.new(StringSort.new).from_const(["ab", "c"]).value).to eq(["ab", "c"])
        expect(SeqSort.new(BoolSort.new).from_const([true, false]).value).to eq([true, false])
      end

      it "raises exception when there's nothing to convert" do
        expect { xs.value }.to raise_error(Z3::Exception)
        expect { (xs + sort.from_const([1])).value }.to raise_error(Z3::Exception)
      end

      it "reads a model" do
        solver = Solver.new
        solver.assert xs.length == 3
        solver.assert xs[0] == 7
        solver.assert xs + sort.from_const([9]) == ys
        expect(solver).to be_satisfiable
        expect(solver.model[xs].value.size).to eq(3)
        expect(solver.model[xs].value[0]).to eq(7)
        expect(solver.model[ys].value).to eq(solver.model[xs].value + [9])
      end
    end

    # `seq.map` / `seq.mapi` / `seq.fold_left` / `seq.fold_lefti`. The block form
    # conjures its own bound variables, so nothing here has to name them.
    describe "#map" do
      it "maps a block over the elements" do
        expect(value_of(xs.map { |x| x * 2 }, xs == sort.from_const([1, 2, 3]))).to eq([2, 4, 6])
        expect(value_of(xs.map { |x| x + 1 }, xs == sort.from_const([]))).to eq([])
      end

      it "changes the element sort to whatever the block returns" do
        expect(xs.map { |x| x > 1 }.sort).to eq(SeqSort.new(BoolSort.new))
        expect(value_of(xs.map { |x| x > 1 }, xs == sort.from_const([1, 2]))).to eq([false, true])
      end

      # The same casting `Z3.Lambda` does for a literal body
      it "takes a Ruby literal as the block's result" do
        expect(value_of(xs.map { |_x| 7 }, xs == sort.from_const([1, 2]))).to eq([7, 7])
      end

      it "chains" do
        expect(value_of(xs.map { |x| x * 2 }.map { |x| x + 1 }, xs == sort.from_const([1, 2]))).to eq([3, 5])
      end

      # A unary function is an ordinary lambda, so no SeqFunction is needed. To Bool
      # it's a Set, to anything else an Array, and #map takes either.
      it "takes a Lambda instead of a block" do
        x = Z3.Int("x")
        expect(Z3.Lambda(x, x * 2)).to be_a(ArrayExpr)
        expect(Z3.Lambda(x, x > 0)).to be_a(SetExpr)
        expect(value_of(xs.map(Z3.Lambda(x, x * 2)), xs == sort.from_const([1, 2]))).to eq([2, 4])
        expect(value_of(xs.map(Z3.Lambda(x, x > 1)), xs == sort.from_const([1, 2]))).to eq([false, true])
      end

      it "raises without a function, with both, or with the wrong one" do
        expect { xs.map }.to raise_error(Z3::Exception, "#map needs a function or a block")
        expect { xs.map(Z3.Lambda(Z3.Int("x"), 1)) { |x| x } }
          .to raise_error(Z3::Exception, "Pass a function or a block, not both")
        expect { xs.map(Z3.Lambda(Z3.Bool("b"), 1)) }
          .to raise_error(Z3::Exception, "#map wants a one argument function over Int, got Array(Bool, Int)")
        expect { xs.map(SeqFunction.from_block(IntSort.new, IntSort.new) { |a, b| a + b }) }
          .to raise_error(Z3::Exception, /#map wants a one argument function over Int/)
      end
    end

    describe "#map_with_index" do
      # Z3's argument order, which is index first
      it "gives the block the index and the element" do
        expect(value_of(xs.map_with_index { |i, x| x * 10 + i }, xs == sort.from_const([1, 2, 3])))
          .to eq([10, 21, 32])
      end

      # Z3 lets the index start anywhere, which Ruby has no spelling for
      it "starts the index at `from:`" do
        expect(value_of(xs.map_with_index(from: 5) { |i, _x| i }, xs == sort.from_const([1, 2, 3])))
          .to eq([5, 6, 7])
      end

      it "takes a SeqFunction instead of a block" do
        f = SeqFunction.from_block(IntSort.new, IntSort.new) { |i, x| x - i }
        expect(value_of(xs.map_with_index(f), xs == sort.from_const([10, 20, 30]))).to eq([10, 19, 28])
      end

      it "is aliased as #mapi, Z3's own name" do
        expect(SeqExpr.instance_method(:mapi)).to eq(SeqExpr.instance_method(:map_with_index))
      end
    end

    describe "#inject" do
      it "folds from the initial value, left to right" do
        expect(value_of(xs.inject(0) { |a, x| a + x }, xs == sort.from_const([1, 2, 3]))).to eq(6)
        expect(value_of(xs.inject(1) { |a, x| a * x }, xs == sort.from_const([2, 3, 4]))).to eq(24)
        expect(value_of(xs.inject(0) { |a, x| a + x }, xs == sort.from_const([]))).to eq(0)
      end

      # Non-commutative, so this pins the argument order down: left to right is 97,
      # right to left would be -97 and (acc, element) swapped would be 1
      it "gives the block the accumulator first" do
        expect(value_of(xs.inject(100) { |a, x| a - x }, xs == sort.from_const([1, 2]))).to eq(97)
      end

      it "accumulates into a different sort than the elements" do
        term = xs.inject(Z3.Const(true)) { |a, x| a & (x > 0) }
        expect(term.sort).to eq(BoolSort.new)
        expect(value_of(term, xs == sort.from_const([1, 2, 3]))).to eq(true)
        expect(value_of(term, xs == sort.from_const([1, -2]))).to eq(false)
      end

      it "takes a SeqFunction instead of a block" do
        f = SeqFunction.from_block(IntSort.new, IntSort.new) { |a, x| a + x }
        expect(value_of(xs.inject(0, f), xs == sort.from_const([1, 2, 3]))).to eq(6)
      end

      it "is aliased as #reduce and as Z3's #fold_left" do
        expect(SeqExpr.instance_method(:reduce)).to eq(SeqExpr.instance_method(:inject))
        expect(SeqExpr.instance_method(:fold_left)).to eq(SeqExpr.instance_method(:inject))
      end

      it "raises without a function, with both, or with the wrong one" do
        expect { xs.inject(0) }.to raise_error(Z3::Exception, "Needs a function or a block")
        expect { xs.inject(0) { |a| a } }
          .to raise_error(Z3::Exception, "Block takes 1 argument, expected 2")
        expect { xs.inject(0, Z3.Lambda(Z3.Int("x"), 1)) }
          .to raise_error(Z3::Exception, "Wanted a SeqFunction over (Int, Int), got Array(Int, Int)")
        expect { xs.inject(0, SeqFunction.from_block(BoolSort.new, IntSort.new) { |a, x| a }) }
          .to raise_error(Z3::Exception, "Wanted a SeqFunction over (Int, Int), got Z3::SeqFunction<(Bool, Int) -> Bool>")
      end
    end

    describe "#inject_with_index" do
      it "gives the block the index, the accumulator and the element" do
        expect(value_of(xs.inject_with_index(0) { |i, a, x| a + x * i }, xs == sort.from_const([5, 5, 5])))
          .to eq(15)
      end

      it "starts the index at `from:`" do
        expect(value_of(xs.inject_with_index(0, from: 1) { |i, a, x| a + i }, xs == sort.from_const([5, 5, 5])))
          .to eq(6)
      end

      it "is aliased as Z3's #fold_lefti" do
        expect(SeqExpr.instance_method(:fold_lefti)).to eq(SeqExpr.instance_method(:inject_with_index))
      end
    end

    # The whole point of having these in a solver rather than in Ruby
    describe "map and fold solve backwards" do
      it "finds a sequence from a fold of it" do
        solver = Solver.new
        solver.assert xs.length == 3
        solver.assert(xs.inject(0) { |a, x| a + x } == 10)
        solver.assert(xs.inject(Z3.Const(true)) { |a, x| a & (x > 0) })
        expect(solver).to be_satisfiable
        elements = solver.model[xs].value
        expect(elements.size).to eq(3)
        expect(elements.sum).to eq(10)
        expect(elements).to all(be > 0)
      end

      it "recovers a sequence from its image" do
        solver = Solver.new
        solver.assert xs.length == 3
        solver.assert(xs.map { |x| x * 2 } == sort.from_const([2, 4, 6]))
        expect(solver).to be_satisfiable
        expect(solver.model[xs].value).to eq([1, 2, 3])
      end

      it "proves a fold can't have the wrong answer" do
        solver = Solver.new
        solver.assert xs == sort.from_const([1, 2, 3])
        solver.assert(xs.inject(0) { |a, x| a + x } == 7)
        expect(solver).to_not be_satisfiable
      end

      it "nests" do
        outer = SeqSort.new(sort)
        qs = outer.var("qs")
        solver = Solver.new
        solver.assert qs == outer.from_const([[1, 2], [3]])
        total = qs.map { |q| q.length }.inject(0) { |a, x| a + x }
        expect(solver).to be_satisfiable
        expect(solver.model[total].value).to eq(3)
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
