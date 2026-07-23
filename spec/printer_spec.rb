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
