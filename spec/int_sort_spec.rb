describe Z3::IntSort do
  it "can instantiate constants" do
    expect(subject.from_const(0).inspect).to eq("Int<0>")
    expect(subject.from_const(42).inspect).to eq("Int<42>")
    expect(subject.from_const(1_000_000_000_000).inspect).to eq("Int<1000000000000>")
    expect(subject.from_const(-1_000_000_000_000).inspect).to eq("Int<-1000000000000>")
  end

  it "raises exception when trying to convert constants of wrong type" do
    expect{ subject.from_const(true) }.to raise_error(Z3::Exception)
    expect{ subject.from_const(false) }.to raise_error(Z3::Exception)
    expect{ subject.from_const(0.0) }.to raise_error(Z3::Exception)
  end

  it "can instantiate variables" do
    expect(Z3.Int("a").inspect).to eq("Int<a>")
  end
end
