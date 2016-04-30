describe Z3::Printer do
  it "numbers" do
    expect(Z3::IntSort.new.from_const(42)).to stringify("42")
    expect(Z3::IntSort.new.from_const(-42)).to stringify("-42")
    expect(Z3::RealSort.new.from_const(42)).to stringify("42")
    expect(Z3::RealSort.new.from_const(-42)).to stringify("-42")
    expect(Z3::RealSort.new.from_const(3.14)).to stringify("157/50")
    expect(Z3::RealSort.new.from_const(-3.14)).to stringify("-157/50")
  end

  it "booleans" do
    expect(Z3.True).to stringify("true")
    expect(Z3.False).to stringify("false")
  end

  it "variables" do
    expect(Z3::Int("a")).to stringify("a")
    expect(Z3::Real("a")).to stringify("a")
    expect(Z3::Bool("a")).to stringify("a")
    expect(Z3::Bitvec("a", 32)).to stringify("a")
  end

  describe "expressions" do
    let(:a) { Z3::Int("a") }
    let(:b) { Z3::Int("b") }
    let(:c) { Z3::Int("c") }

    it "binary operators" do
      expect(a + b).to stringify("(a + b)")
      expect(a - b).to stringify("(a - b)")
      expect(a * b).to stringify("(a * b)")
      expect(a / b).to stringify("div(a, b)")
      expect(a.mod b).to stringify("mod(a, b)")
      expect(a.rem b).to stringify("rem(a, b)")
    end

    it "unary operators" do
      expect(-a).to stringify("(- a)")
    end
  end
end
