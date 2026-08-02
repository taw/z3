module Z3
  describe Printer do
    it "numbers" do
      expect(IntSort.new.from_const(42)).to stringify("42")
      expect(IntSort.new.from_const(-42)).to stringify("-42")
      expect(RealSort.new.from_const(42)).to stringify("42")
      expect(RealSort.new.from_const(-42)).to stringify("-42")
      expect(RealSort.new.from_const(3.14)).to stringify("157/50")
      expect(RealSort.new.from_const(-3.14)).to stringify("-157/50")
    end

    it "numbers as subexpressions" do
      a = Z3.Real("a")
      # Rationals print as `157/50` and negatives carry a leading `-`,
      # so unlike plain integers they are not atomic
      expect(a / RealSort.new.from_const(3.14)).to stringify("a / (157/50)")
      expect(RealSort.new.from_const(3.14) ** 2).to stringify("(157/50) ^ 2")
      expect(-IntSort.new.from_const(-42)).to stringify("-(-42)")
      expect(IntSort.new.from_const(-42) + 1).to stringify("(-42) + 1")
      expect(Z3.Int("b") - IntSort.new.from_const(-42)).to stringify("b - (-42)")
      # Plain non-negative integers are atomic and stay bare
      expect(a / RealSort.new.from_const(42)).to stringify("a / 42")
      expect(Z3.Int("b") + IntSort.new.from_const(42)).to stringify("b + 42")
    end

    it "algebraic numbers as subexpressions" do
      x = Z3.Real("x")
      y = Z3.Real("y")
      negative_root = Solver.new.tap { |s|
        s.assert(x * x == 2)
        s.assert(x < 0)
        expect(s).to be_satisfiable
      }.model[x]
      positive_root = Solver.new.tap { |s|
        s.assert(x * x == 2)
        s.assert(x > 0)
        expect(s).to be_satisfiable
      }.model[x]
      # Don't pin the printed precision, just how it nests
      expect(negative_root.to_s).to start_with("-")
      expect(positive_root.to_s).to_not start_with("-")
      expect((-negative_root).to_s).to eq("-(#{negative_root})")
      expect((y ** negative_root).to_s).to eq("y ^ (#{negative_root})")
      expect((y ** positive_root).to_s).to eq("y ^ #{positive_root}")
    end

    it "booleans" do
      expect(Z3.True).to stringify("true")
      expect(Z3.False).to stringify("false")
    end

    it "variables" do
      expect(Z3.Int("a")).to stringify("a")
      expect(Z3.Real("a")).to stringify("a")
      expect(Z3.Bool("a")).to stringify("a")
      expect(Z3.Bitvec("a", 32)).to stringify("a")
      expect(StringSort.new.var("a")).to stringify("a")
      expect(SeqSort.new(IntSort.new).var("a")).to stringify("a")
      expect(CharSort.new.var("a")).to stringify("a")
    end

    # Values have from_const, but nothing on the Ruby side builds string or seq
    # *operations* yet, so those have to come out of the SMT-LIB2 parser. `q` is the
    # variable being defined, `r` a spare one of the same sort to build them out of.
    def parse_expr(sort, expr)
      solver = Solver.new
      LowLevel.solver_from_string(solver, "(declare-const q #{sort})(declare-const r #{sort})(assert (= q #{expr}))")
      solver.assertions.first.arguments.find { |arg| arg.to_s != "q" }
    end

    describe "strings" do
      let(:sort) { StringSort.new }

      it "string values" do
        expect(sort.from_const("hello")).to stringify(%q{"hello"})
        expect(sort.from_const("")).to stringify(%q{""})
        expect(sort.from_const(%q{a"b})).to stringify(%q{"a\"b"})
      end

      it "string values with escapes" do
        expect(sort.from_const("a\nb\tc")).to stringify(%q{"a\nb\tc"})
        expect(sort.from_const("a\0b")).to stringify(%q{"a\u0000b"})
        # Text that looks like a Z3 escape but isn't one
        expect(sort.from_const(%q{a\u{41}b})).to stringify(%q{"a\\\\u{41}b"})
        expect(sort.from_const("中😀")).to stringify(%q{"中😀"})
      end

      it "string operations" do
        expect(parse_expr("String", %q{(str.++ r "ab")})).to stringify(%q{r + "ab"})
        expect(parse_expr("String", %q{(str.++ "ab" r "cd")})).to stringify(%q{"ab" + r + "cd"})
        expect(parse_expr("String", %q{(str.replace r "a" "b")})).to stringify(%q{str.replace(r, "a", "b")})
      end

      it "char values" do
        expect(CharSort.new.from_const("a")).to stringify(%q{Char("a")})
        expect(CharSort.new.from_const("\n")).to stringify(%q{Char("\n")})
        expect(CharSort.new.from_const("中")).to stringify(%q{Char("中")})
      end
    end

    describe "sequences" do
      let(:int_seq) { SeqSort.new(IntSort.new) }

      it "sequence values" do
        expect(int_seq.from_const([])).to stringify("[]")
        expect(int_seq.from_const([42])).to stringify("[42]")
        expect(int_seq.from_const([1, -2, 3])).to stringify("[1, -2, 3]")
        expect(SeqSort.new(BoolSort.new).from_const([true, false])).to stringify("[true, false]")
      end

      it "nested sequence values" do
        expect(SeqSort.new(int_seq).from_const([[1], []])).to stringify("[[1], []]")
        expect(SeqSort.new(StringSort.new).from_const(["ab", "c"])).to stringify(%q{["ab", "c"]})
      end

      # Concat is associative, and Z3 hands it back as a right-nested binary tree,
      # so it's flattened and runs of units are merged into a single array literal
      it "sequence operations" do
        expect(parse_expr("(Seq Int)", "(seq.++ r (seq.unit 1) (seq.unit 2))")).to stringify("r + [1, 2]")
        expect(parse_expr("(Seq Int)", "(seq.++ (seq.unit 1) r (seq.unit 2))")).to stringify("[1] + r + [2]")
        expect(parse_expr("(Seq Int)", "(seq.++ r r)")).to stringify("r + r")
        expect(parse_expr("(Seq Int)", "(seq.extract r 1 2)")).to stringify("seq.extract(r, 1, 2)")
      end

      it "sequences as subexpressions" do
        concat = parse_expr("(Seq Int)", "(seq.++ r (seq.unit 1))")
        expect(int_seq.var("q") == concat).to stringify("q = (r + [1])")
      end
    end

    describe "expressions" do
      let(:a) { Z3.Int("a") }
      let(:b) { Z3.Int("b") }
      let(:c) { Z3.Int("c") }

      it "binary operators" do
        expect(a + b).to stringify("a + b")
        expect(a - b).to stringify("a - b")
        expect(a * b).to stringify("a * b")
        expect(a / b).to stringify("div(a, b)")
        expect(a.mod b).to stringify("mod(a, b)")
        expect(a.rem b).to stringify("rem(a, b)")
      end

      it "parentheses" do
        expect(a + b + c).to stringify("(a + b) + c")
        expect(a + b * c).to stringify("a + (b * c)")
        expect((a + b) * c).to stringify("(a + b) * c")
        expect(a.mod(b + c)).to stringify("mod(a, b + c)")
        expect(a.mod(b) + c).to stringify("mod(a, b) + c")
      end

      it "unary operators" do
        expect(-a).to stringify("-a")
        expect(-(a + b)).to stringify("-(a + b)")
        expect((-a) + (-b)).to stringify("(-a) + (-b)")
      end
    end

    describe "bitvector operations" do
      let(:a) { Z3.Bitvec("a", 32) }
      let(:b) { Z3.Bitvec("b", 32) }

      it "unary operators" do
        expect(~a).to stringify("~a")
        expect(-a).to stringify("-a")
      end

      it "binary operators" do
        expect(a + b).to stringify("a + b")
        expect(a - b).to stringify("a - b")
        expect(a & b).to stringify("a & b")
        expect(a ^ b).to stringify("a ^ b")
        expect(a | b).to stringify("a | b")
      end

      it "special operators" do
        expect(a.rotate_left(3)).to stringify("rotate_left(a, 3)")
        expect(a.rotate_right(4)).to stringify("rotate_right(a, 4)")
        expect(a.unsigned_lshift(5)).to stringify("bvshl(a, 5)")
        expect(a.signed_rshift(6)).to stringify("bvashr(a, 6)")
        expect(a.unsigned_lshift(7)).to stringify("bvshl(a, 7)")
        expect(a.extract(20, 5)).to stringify("extract(a, 20, 5)")
        expect(a.zero_ext(4)).to stringify("zero_extend(a, 4)")
        expect(a.sign_ext(4)).to stringify("sign_extend(a, 4)")
        expect(a.concat(b)).to stringify("concat(a, b)")
      end
    end
  end
end
