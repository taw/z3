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

    # For the operations the Ruby API can't build - either because they're Z3 spellings
    # with no Ruby name, or because they only ever come back out of a model - the
    # SMT-LIB2 parser builds them instead. `q` is the variable being defined, `r` a
    # spare one of the same sort to build them out of.
    def parse_expr(sort, expr, spare_sort = sort)
      solver = Solver.new
      LowLevel.solver_from_string(solver, "(declare-const q #{sort})(declare-const r #{spare_sort})(assert (= q #{expr}))")
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
      end

      # Everything StringExpr has a Ruby name for prints under that name, so the output
      # can be pasted back in and mean the same thing
      it "string operations as Ruby" do
        r = sort.var("r")
        expect(r.include?("a")).to stringify(%q{r.include?("a")})
        expect(r.start_with?("a")).to stringify(%q{r.start_with?("a")})
        expect(r.end_with?("a")).to stringify(%q{r.end_with?("a")})
        expect(r.index("a")).to stringify(%q{r.index("a")})
        expect(r.index("a", 2)).to stringify(%q{r.index("a", 2)})
        expect(r.rindex("a")).to stringify(%q{r.rindex("a")})
        expect(r.sub("a", "b")).to stringify(%q{r.sub("a", "b")})
        expect(r.gsub("a", "b")).to stringify(%q{r.gsub("a", "b")})
        expect(r.to_i).to stringify("r.to_i")
        expect(r[2]).to stringify("r[2]")
        expect(r[2, 3]).to stringify("r[2, 3]")
        expect(r < "a").to stringify(%q{r < "a"})
        expect(r <= "a").to stringify(%q{r <= "a"})
      end

      # `str.prefixof` takes the prefix first and the string second, so the receiver is
      # the *second* argument - and it's still the one that needs the parentheses
      it "prefixof and suffixof flip their arguments" do
        expect(parse_expr("Bool", %q{(str.prefixof "a" (str.++ r "b"))}, "String")).to stringify(%q{(r + "b").start_with?("a")})
        expect(parse_expr("Bool", %q{(str.suffixof "a" (str.++ r "b"))}, "String")).to stringify(%q{(r + "b").end_with?("a")})
      end

      # `seq.nth` of a String is a Char, which no Ruby method returns - `s[i]` is
      # `str.at`, a one character String - so it keeps the Z3 spelling
      it "operations with no Ruby equivalent keep their Z3 name" do
        nth = CharSort.new.new(LowLevel.mk_seq_nth(sort.var("r"), IntSort.new.from_const(1)))
        expect(nth).to stringify("seq.nth(r, 1)")
        expect(parse_expr("String", "(str.from_int 5)", "String")).to stringify("str.from_int(5)")
      end

      # Operations with a Ruby method of their own print as a call on the receiver
      it "string length" do
        expect(sort.var("r").length).to stringify("r.size")
        expect(sort.from_const("ab").length).to stringify(%q{"ab".size})
        # A method call binds tighter than any operator, so only the receiver needs parens
        expect(parse_expr("Int", %q{(str.len (str.++ r "ab"))}, "String")).to stringify(%q{(r + "ab").size})
        expect(sort.var("r").length + 1).to stringify("r.size + 1")
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
      end

      # A Seq reads like a Ruby Array, so `r[i]` is the element (`seq.nth`) and the
      # subsequence operations print with a length - including `seq.at`, which is a
      # one element sequence and so `r[i, 1]`
      it "sequence operations as Ruby" do
        r = int_seq.var("r")
        expect(r[2]).to stringify("r[2]")
        expect(r[2, 3]).to stringify("r[2, 3]")
        expect(r.include?(1)).to stringify("r.include?(1)")
        expect(r.start_with?(1)).to stringify("r.start_with?(1)")
        expect(r.end_with?([1, 2])).to stringify("r.end_with?([1, 2])")
        expect(r.index(1)).to stringify("r.index(1)")
        expect(r.sub([1], [2])).to stringify("r.sub(1, 2)")
        expect(r.gsub([1], [2])).to stringify("r.gsub(1, 2)")
        expect(parse_expr("(Seq Int)", "(seq.at r 1)")).to stringify("r[1, 1]")
      end

      # `seq.len` and String's `str.len` are one Z3 operation, and print the same way
      it "sequence length" do
        expect(int_seq.var("r").length).to stringify("r.size")
        expect(int_seq.from_const([1, 2]).length).to stringify("[1, 2].size")
        expect(parse_expr("Int", "(seq.len (seq.++ r (seq.unit 1)))", "(Seq Int)")).to stringify("(r + [1]).size")
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
