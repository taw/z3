describe Z3::Value do
  let(:a) { Z3.Int("a") }
  let(:b) { Z3.Int("b") }
  let(:c) { Z3.Bool("c") }
  let(:d) { Z3.Bool("d") }
  let(:e) { Z3.Real("e") }
  let(:f) { Z3.Real("f") }

  it "#sort returns Sort object" do
    expect(a.sort).to eq(Z3::IntSort.new)
    expect(c.sort).to eq(Z3::BoolSort.new)
    expect(e.sort).to eq(Z3::RealSort.new)
  end

  it "#to_s" do
    expect(a.to_s).to eq("a")
  end

  it "#inspect" do
    expect(a.inspect).to eq("Value<a :: Int>")
    expect((e+f).inspect).to eq("Value<(+ e f) :: Real>")
  end

  describe "#~" do
    it "allows negating boolean variables" do
      expect((~c).to_s).to eq("(not c)")
    end

    it "raises exception if type cast is not possible" do
      expect{~a}.to raise_error(NoMethodError)
      expect{~e}.to raise_error(NoMethodError)
    end
  end

  describe "#&" do
    it "allows and of boolean variables" do
      expect((c & d).to_s).to eq("(and c d)")
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
      expect((c | d).to_s).to eq("(or c d)")
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
        expect((a.send op, b).to_s).to eq "(#{op} a b)"
        expect((e.send op, f).to_s).to eq "(#{op} e f)"
      end

      it "casts to correct type if possible" do
        expect((a.send op, e).to_s).to eq "(#{op} (to_real a) e)"
        expect((e.send op, a).to_s).to eq "(#{op} e (to_real a))"
        expect((a.send op, 42).to_s).to eq "(#{op} a 42)"
        expect((42.send op, a).to_s).to eq "(#{op} 42 a)"
        expect((a.send op, 42.5).to_s).to eq "(#{op} (to_real a) (/ 85.0 2.0))"
        expect((42.5.send op, a).to_s).to eq "(#{op} (/ 85.0 2.0) (to_real a))"
        expect((e.send op, 42).to_s).to eq "(#{op} e 42.0)"
        expect((42.send op, e).to_s).to eq "(#{op} 42.0 e)"
        expect((e.send op, 42.5).to_s).to eq "(#{op} e (/ 85.0 2.0))"
        expect((42.5.send op, e).to_s).to eq "(#{op} (/ 85.0 2.0) e)"
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
      expect{a == c}.to raise_error(ArgumentError)
      expect{e == c}.to raise_error(ArgumentError)
      expect{a == true}.to raise_error(ArgumentError)
      expect{e == true}.to raise_error(ArgumentError)
      # expect{true == a}.to raise_error(ArgumentError)
      # expect{true == e}.to raise_error(ArgumentError)
      expect{c == 42}.to raise_error(ArgumentError)
      expect{c == 42.5}.to raise_error(ArgumentError)
      expect{42 == c}.to raise_error(ArgumentError)
      expect{42.5 == c}.to raise_error(ArgumentError)
    end
  end

  describe "#!=" do
    it "allows != of variables of same sort" do
      expect((a != b).to_s).to eq "(distinct a b)"
      expect((c != d).to_s).to eq "(distinct c d)"
      expect((e != f).to_s).to eq "(distinct e f)"
    end

    it "casts to correct type if possible" do
      expect((a != 42).to_s).to eq "(distinct a 42)"
      # expect((42 != a).to_s).to eq "(distinct a 42)"
      expect((a != e).to_s).to eq "(distinct (to_real a) e)"
      expect((e != a).to_s).to eq "(distinct e (to_real a))"
      expect((c != true).to_s).to eq "(distinct c true)"
      expect((c != false).to_s).to eq "(distinct c false)"
      expect((a != 42.5).to_s).to eq "(distinct (to_real a) (/ 85.0 2.0))"
      # expect((42.5 != a).to_s).to eq "(distinct (to_real a) (/ 85.0 2.0))"
      expect((e != 42.5).to_s).to eq "(distinct e (/ 85.0 2.0))"
      # expect((42.5 != e).to_s).to eq "(distinct e (/ 85.0 2.0))"
      # expect((true != c).to_s).to eq "(distinct true c)"
      # expect((false != c).to_s).to eq "(distinct false c)"
    end

    it "raises exception if type cast is not possible" do
      expect{a != c}.to raise_error(ArgumentError)
      expect{e != c}.to raise_error(ArgumentError)
      expect{a != true}.to raise_error(ArgumentError)
      expect{e != true}.to raise_error(ArgumentError)
      # expect{true != a}.to raise_error(ArgumentError)
      # expect{true != e}.to raise_error(ArgumentError)
      expect{c != 42}.to raise_error(ArgumentError)
      expect{c != 42.5}.to raise_error(ArgumentError)
      # expect{42 != c}.to raise_error(ArgumentError)
      # expect{42.5 != c}.to raise_error(ArgumentError)
    end
  end
end