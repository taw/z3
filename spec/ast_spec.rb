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
  end

  describe "#-" do
    it "allows + of int or real variables" do
      expect((a-b).to_s).to eq "(- a b)"
      expect((e-f).to_s).to eq "(- e f)"
    end
  end

  describe "#*" do
    it "allows * of int or real variables" do
      expect((a*b).to_s).to eq "(* a b)"
      expect((e*f).to_s).to eq "(* e f)"
    end
  end

  describe "#==" do
    it "allows == of variables of same sort" do
      expect((a == b).to_s).to eq "(= a b)"
      expect((c == d).to_s).to eq "(= c d)"
      expect((e == f).to_s).to eq "(= e f)"
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
