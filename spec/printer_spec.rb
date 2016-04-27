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
end
