# TODO: This spec doesn't reflect current functionality all that well

module Z3
  describe Expr do
    let(:a) { Z3.Int("a") }
    let(:b) { Z3.Int("b") }
    let(:c) { Z3.Bool("c") }
    let(:d) { Z3.Bool("d") }
    let(:e) { Z3.Real("e") }
    let(:f) { Z3.Real("f") }
    let(:s) { StringSort.new.var("s") }
    let(:t) { StringSort.new.var("t") }
    let(:u) { CharSort.new.var("u") }

    it "#sort returns Sort object" do
      expect(a.sort).to eq(IntSort.new)
      expect(c.sort).to eq(BoolSort.new)
      expect(e.sort).to eq(RealSort.new)
    end

    it "#to_s" do
      expect(a.sexpr).to eq("a")
    end

    it "#inspect" do
      expect(a.inspect).to eq("Int<a>")
      expect((e+f).inspect).to eq("Real<e + f>")
    end

    # Reachable from Z3.And(*conditions) when the array turns out to be empty
    it "variadic operators reject an empty argument list" do
      %w[And Or Xor Add Sub Mul].each do |op|
        expect{ Expr.send(op) }.to raise_error(Z3::Exception, /#{op} requires at least one argument/)
      end
    end

    describe "#~" do
      it "allows negating boolean variables" do
        expect((~c).sexpr).to eq("(not c)")
      end

      it "raises exception if type cast is not possible" do
        expect{~a}.to raise_error(NoMethodError)
        expect{~e}.to raise_error(NoMethodError)
      end
    end

    describe "#&" do
      it "allows and of boolean variables" do
        expect((c & d).sexpr).to eq("(and c d)")
      end

      it "raises exception if type cast is not possible" do
        expect{a&b}.to raise_error(NoMethodError)
        expect{e&f}.to raise_error(NoMethodError)
        expect{a&c}.to raise_error(NoMethodError)
        expect{e&c}.to raise_error(NoMethodError)
        expect{c&a}.to raise_error(ArgumentError)
        expect{c&e}.to raise_error(ArgumentError)
      end
    end

    describe "#|" do
      it "allows or of boolean variables" do
        expect((c | d).sexpr).to eq("(or c d)")
      end

      it "raises exception if type cast is not possible" do
        expect{a|b}.to raise_error(NoMethodError)
        expect{e|f}.to raise_error(NoMethodError)
        expect{a|c}.to raise_error(NoMethodError)
        expect{e|c}.to raise_error(NoMethodError)
        expect{c|a}.to raise_error(ArgumentError)
        expect{c|e}.to raise_error(ArgumentError)
      end
    end

    %W[+ - * <= < >= >].each do |op|
      describe "#{op} arithmetic operator" do
        it "allows + of int or real variables" do
          expect(a.send(op, b).sexpr).to eq "(#{op} a b)"
          expect(e.send(op, f).sexpr).to eq "(#{op} e f)"
        end

        it "casts to correct type if possible" do
          expect(a.send(op, e).sexpr).to eq "(#{op} (to_real a) e)"
          expect(e.send(op, a).sexpr).to eq "(#{op} e (to_real a))"
          expect(a.send(op, 42).sexpr).to eq "(#{op} a 42)"
          expect(42.send(op, a).sexpr).to eq "(#{op} 42 a)"
          expect(a.send(op, 42.5).sexpr).to eq "(#{op} (to_real a) (/ 85.0 2.0))"
          expect(42.5.send(op, a).sexpr).to eq "(#{op} (/ 85.0 2.0) (to_real a))"
          expect(a.send(op, Rational(19, 7)).sexpr).to eq "(#{op} (to_real a) (/ 19.0 7.0))"
          expect(Rational(19, 7).send(op, a).sexpr).to eq "(#{op} (/ 19.0 7.0) (to_real a))"
          expect(e.send(op, 42).sexpr).to eq "(#{op} e 42.0)"
          expect(42.send(op, e).sexpr).to eq "(#{op} 42.0 e)"
          expect(e.send(op, 42.5).sexpr).to eq "(#{op} e (/ 85.0 2.0))"
          expect(42.5.send(op, e).sexpr).to eq "(#{op} (/ 85.0 2.0) e)"
          expect(e.send(op, Rational(19, 7)).sexpr).to eq "(#{op} e (/ 19.0 7.0))"
          expect(Rational(19, 7).send(op, e).sexpr).to eq "(#{op} (/ 19.0 7.0) e)"
        end

        it "raises exception if type cast is not possible" do
          # Int/Real has #>= #+ etc. but they don't like these arguments
          expect{a.send op, c}.to raise_error(ArgumentError)
          expect{e.send op, c}.to raise_error(ArgumentError)
          expect{a.send op, true}.to raise_error(ArgumentError)
          expect{a.send op, false}.to raise_error(ArgumentError)
          expect{e.send op, true}.to raise_error(ArgumentError)
          expect{e.send op, false}.to raise_error(ArgumentError)

          # Bool doesn't have #>= #+ etc.
          expect{c.send op, a}.to raise_error(NoMethodError)
          expect{c.send op, d}.to raise_error(NoMethodError)
          expect{c.send op, e}.to raise_error(NoMethodError)
          expect{c.send op, true}.to raise_error(NoMethodError)
          expect{c.send op, false}.to raise_error(NoMethodError)
        end
      end
    end

    describe "#==" do
      it "allows == of variables of same sort" do
        expect((a == b).sexpr).to eq "(= a b)"
        expect((c == d).sexpr).to eq "(= c d)"
        expect((e == f).sexpr).to eq "(= e f)"
        expect((s == t).sexpr).to eq "(= s t)"
      end

      it "casts to correct type if possible" do
        expect((a == 42).sexpr).to eq "(= a 42)"
        expect((42 == a).sexpr).to eq "(= 42 a)"
        expect((a == e).sexpr).to eq "(= (to_real a) e)"
        expect((e == a).sexpr).to eq "(= e (to_real a))"
        expect((c == true).sexpr).to eq "(= c true)"
        expect((c == false).sexpr).to eq "(= c false)"
        expect((a == 42.5).sexpr).to eq "(= (to_real a) (/ 85.0 2.0))"
        expect((42.5 == a).sexpr).to eq "(= (/ 85.0 2.0) (to_real a))"
        expect((e == 42.5).sexpr).to eq "(= e (/ 85.0 2.0))"
        expect((42.5 == e).sexpr).to eq "(= (/ 85.0 2.0) e)"
        expect((Rational(19, 7) == e).sexpr).to eq "(= (/ 19.0 7.0) e)"
        expect((e == Rational(19, 7)).sexpr).to eq "(= e (/ 19.0 7.0))"
        expect((true == c).sexpr).to eq "(= c true)"
        expect((false == c).sexpr).to eq "(= c false)"
        expect((s == "abc").sexpr).to eq %q{(= s "abc")}
        expect(("abc" == s).sexpr).to eq %q{(= s "abc")}
      end

      it "raises exception if type cast is not possible" do
        expect{a == c}.to raise_error(ArgumentError)
        expect{e == c}.to raise_error(ArgumentError)
        expect{a == true}.to raise_error(ArgumentError)
        expect{e == true}.to raise_error(ArgumentError)
        expect{true == a}.to raise_error(ArgumentError)
        expect{true == e}.to raise_error(ArgumentError)
        expect{c == 42}.to raise_error(ArgumentError)
        expect{c == 42.5}.to raise_error(ArgumentError)
        expect{42 == c}.to raise_error(ArgumentError)
        expect{42.5 == c}.to raise_error(ArgumentError)
        expect{a == "abc"}.to raise_error(ArgumentError)
        expect{"abc" == a}.to raise_error(ArgumentError)
        expect{s == 42}.to raise_error(ArgumentError)
        expect{s == true}.to raise_error(ArgumentError)
      end

      # Sorts are only partially ordered, so the failure has to name them itself -
      # Array#max would answer with Ruby class names, and two enums are both EnumSort
      it "names both sorts when neither can be cast to the other" do
        red = EnumSort.new("MismatchRed", %i[x y]).var("r")
        blue = EnumSort.new("MismatchBlue", %i[x y]).var("b")
        expect{a == c}.to raise_error(ArgumentError, "Can't convert Bool into Int")
        expect{c == 42}.to raise_error(ArgumentError, "Can't convert Int into Bool")
        expect{s == 42}.to raise_error(ArgumentError, "Can't convert Int into String")
        expect{red == blue}.to raise_error(ArgumentError, "Can't convert MismatchBlue into MismatchRed")
        expect{blue == red}.to raise_error(ArgumentError, "Can't convert MismatchRed into MismatchBlue")
      end

      # Ruby has no character type, so a String is always a String, never a Char -
      # `CharSort.new.from_const("a")` is how you say that
      it "does not autoconvert Strings to Chars" do
        expect{u == "a"}.to raise_error(ArgumentError)
        expect{"a" == u}.to raise_error(ArgumentError)
        expect((u == CharSort.new.from_const("a")).sexpr).to eq "(= u (_ Char 97))"
      end

      # We prepend to String#== to make `"abc" == s` work, so plain Ruby == must survive
      it "leaves == of Strings which aren't exprs alone" do
        expect("abc" == "abc").to be true
        expect("abc" == "abd").to be false
        expect("abc" == 42).to be false
        expect("abc" != "abd").to be true
      end

      # Same for Symbol#==, which we prepend to for `:red == color_var`
      it "leaves == of Symbols which aren't exprs alone" do
        expect(:abc == :abc).to be true
        expect(:abc == :abd).to be false
        expect(:abc == "abc").to be false
        expect(:abc != :abd).to be true
        expect({abc: 1}[:abc]).to eq 1
      end
    end

    describe "#!=" do
      it "allows != of variables of same sort" do
        expect((a != b).sexpr).to eq "(distinct a b)"
        expect((c != d).sexpr).to eq "(distinct c d)"
        expect((e != f).sexpr).to eq "(distinct e f)"
      end

      it "casts to correct type if possible" do
        expect((a != 42).sexpr).to eq "(distinct a 42)"
        expect((42 != a).sexpr).to eq "(distinct 42 a)"
        expect((a != e).sexpr).to eq "(distinct (to_real a) e)"
        expect((e != a).sexpr).to eq "(distinct e (to_real a))"
        expect((c != true).sexpr).to eq "(distinct c true)"
        expect((c != false).sexpr).to eq "(distinct c false)"
        expect((a != 42.5).sexpr).to eq "(distinct (to_real a) (/ 85.0 2.0))"
        expect((42.5 != a).sexpr).to eq "(distinct (/ 85.0 2.0) (to_real a))"
        expect((e != 42.5).sexpr).to eq "(distinct e (/ 85.0 2.0))"
        expect((42.5 != e).sexpr).to eq "(distinct (/ 85.0 2.0) e)"
        expect((true != c).sexpr).to eq "(distinct c true)"
        expect((false != c).sexpr).to eq "(distinct c false)"
        expect((s != "abc").sexpr).to eq %q{(distinct s "abc")}
        expect(("abc" != s).sexpr).to eq %q{(distinct s "abc")}
      end

      it "raises exception if type cast is not possible" do
        expect{a != c}.to raise_error(ArgumentError)
        expect{e != c}.to raise_error(ArgumentError)
        expect{a != true}.to raise_error(ArgumentError)
        expect{e != true}.to raise_error(ArgumentError)
        expect{true != a}.to raise_error(ArgumentError)
        expect{true != e}.to raise_error(ArgumentError)
        expect{c != 42}.to raise_error(ArgumentError)
        expect{c != 42.5}.to raise_error(ArgumentError)
        expect{c != Rational(19, 7)}.to raise_error(ArgumentError)
        expect{42 != c}.to raise_error(ArgumentError)
        expect{Rational(19, 7) != c}.to raise_error(ArgumentError)
        expect{a != "abc"}.to raise_error(ArgumentError)
        expect{"abc" != a}.to raise_error(ArgumentError)
        expect{s != 42}.to raise_error(ArgumentError)
        expect{u != "a"}.to raise_error(ArgumentError)
      end
    end

    describe "#substitute" do
      let(:x) { Z3.Int("x") }

      it "replaces a variable" do
        expect((a + b).substitute(a => x)).to stringify("x + b")
      end

      it "replaces every occurrence of it" do
        expect(((a + b) * (a - b)).substitute(a => x)).to stringify("(x + b) * (x - b)")
      end

      it "replaces more than one thing at a time" do
        expect((a + b).substitute(a => x, b => 2)).to stringify("x + 2")
      end

      # Doing them one after another would leave `b - b` or `a - a` instead
      it "replaces everything simultaneously" do
        expect((a - b).substitute(a => b, b => a)).to stringify("b - a")
      end

      # Keys match whole subterms, so they don't have to be variables
      it "replaces compound subterms" do
        expect(((a + b) * 2).substitute((a + b) => x)).to stringify("x * 2")
      end

      it "coerces each replacement to the sort of what it replaces" do
        expect((a + b).substitute(a => 5)).to stringify("5 + b")
        expect((s + t).substitute(s => "hello")).to stringify(%q{"hello" + t})
      end

      it "does nothing when nothing matches" do
        expect((a + b).substitute(x => a)).to stringify("a + b")
      end

      it "works on any sort" do
        expect((c | d).substitute(c => (a > 1))).to stringify("or(a > 1, d)")
        expect((s + t).substitute(s => "hello")).to stringify(%q{"hello" + t})
      end

      it "keeps the sort of the expression it rewrote" do
        expect((a + b).substitute(a => x).sort).to eq(IntSort.new)
        expect((c | d).substitute(c => (a > 1)).sort).to eq(BoolSort.new)
        expect((s + t).substitute(s => "x").sort).to eq(StringSort.new)
      end

      it "returns the expression itself when there's nothing to replace" do
        expr = a + b
        expect(expr.substitute({})).to equal(expr)
      end

      it "returns something the solver can use" do
        expect([(a + b == 10).substitute(b => x), x == 4]).to have_solution(a => 6)
      end

      it "raises unless every key is an expr" do
        expect{ (a + b).substitute(1 => 2) }
          .to raise_error(Z3::Exception, "Can't substitute for Integer, only for exprs")
        expect{ (a + b).substitute(nil => 2) }
          .to raise_error(Z3::Exception, "Can't substitute for nil, only for exprs")
      end

      it "raises when a replacement doesn't fit what it replaces" do
        expect{ (a + b).substitute(a => c) }
          .to raise_error(Z3::Exception, "Can't convert Bool into Int")
        expect{ (a + b).substitute(a => :abc) }
          .to raise_error(Z3::Exception, "Can't convert :abc into Int")
      end

      it "raises unless given a Hash" do
        expect{ (a + b).substitute([[a, x]]) }
          .to raise_error(Z3::Exception, "Hash of replacements required")
      end
    end

    describe ".sort_for_const" do
      it "knows the sorts Ruby values map to" do
        expect(Expr.sort_for_const(true)).to eq(BoolSort.new)
        expect(Expr.sort_for_const(false)).to eq(BoolSort.new)
        expect(Expr.sort_for_const(42)).to eq(IntSort.new)
        expect(Expr.sort_for_const(42.5)).to eq(RealSort.new)
        expect(Expr.sort_for_const(Rational(19, 7))).to eq(RealSort.new)
        expect(Expr.sort_for_const("abc")).to eq(StringSort.new)
        expect(Expr.sort_for_const("a")).to eq(StringSort.new)
      end

      it "raises exception for Ruby values with no sort" do
        expect{Expr.sort_for_const(nil)}.to raise_error(Z3::Exception, "No Z3 sort for nil")
        expect{Expr.sort_for_const([1, 2])}.to raise_error(Z3::Exception, "No Z3 sort for Array")
      end

      # Ruby names the receiver when coercion fails - `1 + Object.new` raises
      # "Object can't be coerced into Integer" - so a failure with a sort in hand
      # says the same thing about the sort
      it "reports failures against the sort it was coercing towards" do
        expect{Z3.Int("a") + :abc}.to raise_error(Z3::Exception, ":abc can't be coerced into Int")
        expect{Z3.Int("a") + nil}.to raise_error(Z3::Exception, "nil can't be coerced into Int")
        expect{Z3.Int("a").coerce(:abc)}.to raise_error(Z3::Exception, ":abc can't be coerced into Int")
        expect{Z3.Bitvec("v", 8) + :abc}.to raise_error(Z3::Exception, ":abc can't be coerced into Bitvec(8)")
        expect{Z3.String("s") + :abc}.to raise_error(Z3::Exception, ":abc can't be coerced into String")
      end

      # With no Expr among the arguments nothing was being coerced towards anything
      it "reports no sort at all when there's nothing to coerce towards" do
        expect{Z3.Add(1, nil)}.to raise_error(Z3::Exception, "No Z3 sort for nil")
      end

      # "No Z3 sort for :red" would be true but unhelpful - a Symbol does have a sort,
      # it's just that only the enum it belongs to knows which, and nothing here names one
      it "says which way round a bare Symbol has to be built" do
        message = "Can't tell which enum :red belongs to, ask the sort for it instead - `enum_sort[:red]`"
        expect{Expr.sort_for_const(:red)}.to raise_error(Z3::Exception, message)
        expect{Z3.Const(:red)}.to raise_error(Z3::Exception, message)
        expect{Z3.Add(1, :red)}.to raise_error(Z3::Exception, message)
      end

      # A Symbol is the one value whose sort comes from the other side rather than
      # from itself - it's an enum value, and enums don't share a namespace
      it "gives a Symbol the enum sort it's being coerced towards" do
        sort = EnumSort.new("SortForConst", %i[a b])
        expect(Expr.sort_for_const(:a, toward: sort)).to eq(sort)
        expect(Expr.sort_for_const(:nope, toward: sort)).to eq(sort)
        expect{Expr.sort_for_const(:a, toward: IntSort.new)}.to raise_error(Z3::Exception, ":a can't be coerced into Int")
      end
    end
  end

  describe "#hash / #eql?" do
    let(:x1) { Z3.Int("x") }
    let(:x2) { Z3.Int("x") }
    let(:y1) { Z3.Int("y") }
    let(:y2) { Z3.Int("y") }
    let(:e1) { x1 + y1 }
    let(:e2) { x2 + y2 }
    let(:f1) { y1 + x1 }
    let(:f2) { y2 + x2 }
    let(:samples) { [x1, x2, y1, y2, e1, e2, f1, f2] }

    it "object is eql? to itself" do
      expect(x1.eql?(x1)).to be true
      expect(y1.eql?(y1)).to be true
      expect(e1.eql?(e1)).to be true

      expect(x1.eql?(y1)).to be false
      expect(x1.eql?(e1)).to be false
    end

    it "object is eql? to structurally identical object" do
      expect(x1.eql?(x2)).to be true
      expect(y1.eql?(y2)).to be true
      expect(e1.eql?(e2)).to be true
      expect(f1.eql?(f2)).to be true
    end

    it "object is not eql? to semantically identical object" do
      expect(e1.eql?(f1)).to be false
    end

    it "#hash aligns with #eql?" do
      samples.each do |a|
        samples.each do |b|
          if a.eql?(b)
            expect(a.hash).to eq(b.hash)
          else
            expect(a.hash).to_not eq(b.hash)
          end
        end
      end
    end

    it "works when used as Hash keys" do
      ht = {}
      ht[x1] = 1
      ht[y1] = 2
      ht[e1] = 3
      ht[e2] = 4

      expect(ht.size).to eq(3)
      expect(ht[x1]).to eq(1)
      expect(ht[x2]).to eq(1)
      expect(ht[y1]).to eq(2)
      expect(ht[y2]).to eq(2)
      expect(ht[e1]).to eq(4)
      expect(ht[e2]).to eq(4)
      expect(ht[f1]).to eq(nil)
      expect(ht[f2]).to eq(nil)
    end
  end
end
