describe Z3::RealSort do
  it "can instantiate constants" do
    expect(subject.from_const(0).inspect).to eq("Value<0 :: Real>")
    expect(subject.from_const(42).inspect).to eq("Value<42 :: Real>")
    expect(subject.from_const(1_000_000_000_000).inspect).to eq("Value<1000000000000 :: Real>")
    expect(subject.from_const(-1_000_000_000_000).inspect).to eq("Value<-1000000000000 :: Real>")
    expect(subject.from_const(0.0).inspect).to eq("Value<0 :: Real>")
    expect(subject.from_const(-0.0).inspect).to eq("Value<0 :: Real>")
    expect(subject.from_const(3.14).inspect).to eq("Value<157/50 :: Real>")
    expect(subject.from_const(-3.14).inspect).to eq("Value<-157/50 :: Real>")
  end

  it "raises exception when trying to convert constants of wrong type" do
    expect{ subject.from_const(true) }.to raise_error(Z3::Exception)
    expect{ subject.from_const(false) }.to raise_error(Z3::Exception)
    expect{ subject.from_const(1.0 / 0.0) }.to raise_error(Z3::Exception)
    expect{ subject.from_const(-1.0 / 0.0) }.to raise_error(Z3::Exception)
    expect{ subject.from_const(0.0 / 0.0) }.to raise_error(Z3::Exception)
  end

  it "can instantiate variables" do
    expect(Z3.Real("a").inspect).to eq("Value<a :: Real>")
  end
end
