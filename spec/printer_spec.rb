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

    # Nothing on the Ruby side builds string or seq exprs yet, so the only way to get one
    # is to let Z3 parse it. `q` is the variable being defined, `r` a spare one of the
    # same sort to build symbolic exprs out of.
    def parse_expr(sort, expr)
      solver = Solver.new
      LowLevel.solver_from_string(solver, "(declare-const q #{sort})(declare-const r #{sort})(assert (= q #{expr}))")
      solver.assertions.first.arguments.find { |arg| arg.to_s != "q" }
    end

    describe "strings" do
      it "string values" do
        expect(parse_expr("String", %q{"hello"})).to stringify(%q{"hello"})
        expect(parse_expr("String", %q{""})).to stringify(%q{""})
        # `""` is how SMT-LIB2 escapes a quote
        expect(parse_expr("String", %q{"a""b"})).to stringify(%q{"a\"b"})
      end

      it "string values with escapes" do
        expect(parse_expr("String", %q{"a\u{a}b\u{9}c"})).to stringify(%q{"a\nb\tc"})
        expect(parse_expr("String", %q{"a\u{0}b"})).to stringify(%q{"a\u0000b"})
        # A backslash is only special to Z3 when it starts an escape, and this one doesn't
        expect(parse_expr("String", %q{"a\u{5c}u{41}b"})).to stringify(%q{"a\\\\u{41}b"})
        expect(parse_expr("String", %q{"\u{4e2d}\u{1f600}"})).to stringify(%q{"中😀"})
      end

      it "string operations" do
        expect(parse_expr("String", %q{(str.++ r "ab")})).to stringify(%q{r + "ab"})
        expect(parse_expr("String", %q{(str.++ "ab" r "cd")})).to stringify(%q{"ab" + r + "cd"})
        expect(parse_expr("String", %q{(str.replace r "a" "b")})).to stringify(%q{str.replace(r, "a", "b")})
      end

      it "char values" do
        expect(Expr.new_from_pointer(LowLevel.mk_char("a".ord))).to stringify(%q{Char("a")})
        expect(Expr.new_from_pointer(LowLevel.mk_char("\n".ord))).to stringify(%q{Char("\n")})
        expect(Expr.new_from_pointer(LowLevel.mk_char("中".ord))).to stringify(%q{Char("中")})
      end
    end

    describe "sequences" do
      it "sequence values" do
        expect(parse_expr("(Seq Int)", "(as seq.empty (Seq Int))")).to stringify("[]")
        expect(parse_expr("(Seq Int)", "(seq.unit 42)")).to stringify("[42]")
        expect(parse_expr("(Seq Int)", "(seq.++ (seq.unit 1) (seq.unit (- 2)) (seq.unit 3))")).to stringify("[1, -2, 3]")
        expect(parse_expr("(Seq Bool)", "(seq.++ (seq.unit true) (seq.unit false))")).to stringify("[true, false]")
      end

      it "nested sequence values" do
        expect(
          parse_expr("(Seq (Seq Int))", "(seq.++ (seq.unit (seq.unit 1)) (seq.unit (as seq.empty (Seq Int))))")
        ).to stringify("[[1], []]")
        expect(parse_expr("(Seq String)", %q{(seq.++ (seq.unit "ab") (seq.unit "c"))})).to stringify(%q{["ab", "c"]})
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
        solver = Solver.new
        LowLevel.solver_from_string(solver, "(declare-const q (Seq Int))(assert (= q (seq.++ q (seq.unit 1))))")
        expect(solver.assertions.first).to stringify("q = (q + [1])")
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
