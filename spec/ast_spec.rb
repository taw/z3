describe Z3::Ast do
  let(:a) { Z3::Ast.int("a") }
  let(:b) { Z3::Ast.int("b") }
  let(:c) { Z3::Ast.bool("c") }
  let(:d) { Z3::Ast.bool("d") }
  let(:e) { Z3::Ast.real("e") }
  let(:f) { Z3::Ast.real("f") }

  it "#sort returns Sort object" do
    expect(a.sort).to eq(Z3::Sort.int)
    expect(c.sort).to eq(Z3::Sort.bool)
    expect(e.sort).to eq(Z3::Sort.real)
  end

  it "#to_s" do
    expect(a.to_s).to eq("a")
  end

  it "#inspect" do
    expect(a.inspect).to eq("Z3::Ast<a :: Int>")
    expect((e+f).inspect).to eq("Z3::Ast<(+ e f) :: Real>")
  end

  describe "#~" do
    it "allows negating boolean variables" do
      expect((~c).to_s).to eq("(not c)")
    end
  end

  describe "#&" do
    it "allows and of boolean variables" do
      expect((c & d).to_s).to eq("(and c d)")
    end
  end

  describe "#|" do
    it "allows or of boolean variables" do
      expect((c | d).to_s).to eq("(or c d)")
    end
  end

  describe "#+" do
    it "allows + of int or real variables" do
      expect((a+b).to_s).to eq "(+ a b)"
      expect((e+f).to_s).to eq "(+ e f)"
    end

    it "casts to correct type if possible" do
      expect((a+e).to_s).to eq "(+ (to_real a) e)"
      expect((e+a).to_s).to eq "(+ e (to_real a))"
      expect((a+42).to_s).to eq "(+ a 42)"
      expect((42+a).to_s).to eq "(+ 42 a)"
      expect((a+42.5).to_s).to eq "(+ (to_real a) (/ 85.0 2.0))"
      expect((42.5+a).to_s).to eq "(+ (/ 85.0 2.0) (to_real a))"
      expect((e+42).to_s).to eq "(+ e 42.0)"
      expect((42+e).to_s).to eq "(+ 42.0 e)"
      expect((e+42.5).to_s).to eq "(+ e (/ 85.0 2.0))"
      expect((42.5+e).to_s).to eq "(+ (/ 85.0 2.0) e)"
    end

    it "raises exception if type cast is not possible" do
      expect{a+c}.to raise_error(Z3::Exception)
      expect{c+a}.to raise_error(Z3::Exception)
      expect{e+c}.to raise_error(Z3::Exception)
      expect{c+e}.to raise_error(Z3::Exception)
      expect{c+d}.to raise_error(Z3::Exception)
      expect{a+true}.to raise_error(Z3::Exception)
      expect{c+true}.to raise_error(Z3::Exception)
      expect{e+true}.to raise_error(Z3::Exception)
      expect{a+false}.to raise_error(Z3::Exception)
      expect{c+false}.to raise_error(Z3::Exception)
      expect{e+false}.to raise_error(Z3::Exception)
    end
  end

  describe "#-" do
    it "allows + of int or real variables" do
      expect((a-b).to_s).to eq "(- a b)"
      expect((e-f).to_s).to eq "(- e f)"
    end

    it "casts to correct type if possible" do
      expect((a-e).to_s).to eq "(- (to_real a) e)"
      expect((e-a).to_s).to eq "(- e (to_real a))"
      expect((a-42).to_s).to eq "(- a 42)"
      expect((42-a).to_s).to eq "(- 42 a)"
      expect((a-42.5).to_s).to eq "(- (to_real a) (/ 85.0 2.0))"
      expect((42.5-a).to_s).to eq "(- (/ 85.0 2.0) (to_real a))"
      expect((e-42).to_s).to eq "(- e 42.0)"
      expect((42-e).to_s).to eq "(- 42.0 e)"
      expect((e-42.5).to_s).to eq "(- e (/ 85.0 2.0))"
      expect((42.5-e).to_s).to eq "(- (/ 85.0 2.0) e)"
    end

    it "raises exception if type cast is not possible" do
      expect{a-c}.to raise_error(Z3::Exception)
      expect{c-a}.to raise_error(Z3::Exception)
      expect{e-c}.to raise_error(Z3::Exception)
      expect{c-e}.to raise_error(Z3::Exception)
      expect{c-d}.to raise_error(Z3::Exception)
      expect{a-true}.to raise_error(Z3::Exception)
      expect{c-true}.to raise_error(Z3::Exception)
      expect{e-true}.to raise_error(Z3::Exception)
      expect{a-false}.to raise_error(Z3::Exception)
      expect{c-false}.to raise_error(Z3::Exception)
      expect{e-false}.to raise_error(Z3::Exception)
    end
  end

  describe "#*" do
    it "allows * of int or real variables" do
      expect((a*b).to_s).to eq "(* a b)"
      expect((e*f).to_s).to eq "(* e f)"
    end

    it "casts to correct type if possible" do
      expect((a*e).to_s).to eq "(* (to_real a) e)"
      expect((e*a).to_s).to eq "(* e (to_real a))"
      expect((a*42).to_s).to eq "(* a 42)"
      expect((42*a).to_s).to eq "(* 42 a)"
      expect((a*42.5).to_s).to eq "(* (to_real a) (/ 85.0 2.0))"
      expect((42.5*a).to_s).to eq "(* (/ 85.0 2.0) (to_real a))"
      expect((e*42).to_s).to eq "(* e 42.0)"
      expect((42*e).to_s).to eq "(* 42.0 e)"
      expect((e*42.5).to_s).to eq "(* e (/ 85.0 2.0))"
      expect((42.5*e).to_s).to eq "(* (/ 85.0 2.0) e)"
    end

    it "raises exception if type cast is not possible" do
      expect{a*c}.to raise_error(Z3::Exception)
      expect{c*a}.to raise_error(Z3::Exception)
      expect{e*c}.to raise_error(Z3::Exception)
      expect{c*e}.to raise_error(Z3::Exception)
      expect{c*d}.to raise_error(Z3::Exception)
      expect{a*true}.to raise_error(Z3::Exception)
      expect{c*true}.to raise_error(Z3::Exception)
      expect{e*true}.to raise_error(Z3::Exception)
      expect{a*false}.to raise_error(Z3::Exception)
      expect{c*false}.to raise_error(Z3::Exception)
      expect{e*false}.to raise_error(Z3::Exception)
    end
  end

  describe "#==" do
    it "allows == of variables of same sort" do
      expect((a == b).to_s).to eq "(= a b)"
      expect((c == d).to_s).to eq "(= c d)"
      expect((e == f).to_s).to eq "(= e f)"
    end

    it "casts to correct type if possible" do
      expect((a == 42).to_s).to eq "(= a 42)"
      expect((42 == a).to_s).to eq "(= a 42)"
      expect((a == e).to_s).to eq "(= (to_real a) e)"
      expect((e == a).to_s).to eq "(= e (to_real a))"
      expect((c == true).to_s).to eq "(= c true)"
      expect((c == false).to_s).to eq "(= c false)"
      expect((a == 42.5).to_s).to eq "(= (to_real a) (/ 85.0 2.0))"
      expect((42.5 == a).to_s).to eq "(= (to_real a) (/ 85.0 2.0))"
      expect((e == 42.5).to_s).to eq "(= e (/ 85.0 2.0))"
      expect((42.5 == e).to_s).to eq "(= e (/ 85.0 2.0))"
      # expect((true == c).to_s).to eq "(= true c)"
      # expect((false == c).to_s).to eq "(= false c)"
    end

    it "raises exception if type cast is not possible" do
      expect{a == c}.to raise_error(Z3::Exception)
      expect{e == c}.to raise_error(Z3::Exception)
      expect{a == true}.to raise_error(Z3::Exception)
      expect{e == true}.to raise_error(Z3::Exception)
      # expect{true == a}.to raise_error(Z3::Exception)
      # expect{true == e}.to raise_error(Z3::Exception)
      expect{c == 42}.to raise_error(Z3::Exception)
      expect{c == 42.5}.to raise_error(Z3::Exception)
      expect{42 == c}.to raise_error(Z3::Exception)
      expect{42.5 == c}.to raise_error(Z3::Exception)
    end
  end

  describe "#!=" do
    it "allows != of variables of same sort" do
      expect((a != b).to_s).to eq "(distinct a b)"
      expect((c != d).to_s).to eq "(distinct c d)"
      expect((e != f).to_s).to eq "(distinct e f)"
    end
  end

  describe "comparisons" do
    it "allows >= of numeric variables" do
      expect((a >= b).to_s).to eq "(>= a b)"
      expect((e >= f).to_s).to eq "(>= e f)"
    end
  end

  describe "comparisons" do
    it "allows > of numeric variables" do
      expect((a > b).to_s).to eq "(> a b)"
      expect((e > f).to_s).to eq "(> e f)"
    end
  end

  describe "comparisons" do
    it "allows <= of numeric variables" do
      expect((a <= b).to_s).to eq "(<= a b)"
      expect((e <= f).to_s).to eq "(<= e f)"
    end
  end

  describe "comparisons" do
    it "allows < of numeric variables" do
      expect((a < b).to_s).to eq "(< a b)"
      expect((e < f).to_s).to eq "(< e f)"
    end
  end
end
