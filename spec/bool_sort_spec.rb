describe Z3::BoolSort do
  it "can instantiate constants" do
    expect(subject.from_const(true).inspect).to eq("Value<true :: Bool>")
    expect(subject.from_const(false).inspect).to eq("Value<false :: Bool>")
  end

  it "raises exception when trying to convert constants of wrong type" do
    expect{ subject.from_const(0) }.to raise_error(Z3::Exception)
    expect{ subject.from_const(0.0) }.to raise_error(Z3::Exception)
  end

  it "interface constructors" do
    expect(Z3.True.inspect).to eq("Value<true :: Bool>")
    expect(Z3.False.inspect).to eq("Value<false :: Bool>")
  end

  it "can instantiate variables" do
    expect(Z3.Bool("a").inspect).to eq("Value<a :: Bool>")
  end
end
