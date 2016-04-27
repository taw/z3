describe Z3::BoolSort do
  it "can instantiate constants" do
    expect(subject.from_const(true).inspect).to eq("Bool<true>")
    expect(subject.from_const(false).inspect).to eq("Bool<false>")
  end

  it "raises exception when trying to convert constants of wrong type" do
    expect{ subject.from_const(0) }.to raise_error(Z3::Exception)
    expect{ subject.from_const(0.0) }.to raise_error(Z3::Exception)
  end

  it "interface constructors" do
    expect(Z3.True.inspect).to eq("Bool<true>")
    expect(Z3.False.inspect).to eq("Bool<false>")
  end

  it "can instantiate variables" do
    expect(Z3.Bool("a").inspect).to eq("Bool<a>")
  end
end
