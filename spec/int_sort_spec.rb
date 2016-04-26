describe Z3::IntSort do
  it "can instantiate constants" do
    expect(subject.from_const(0).inspect).to eq("Value<0 :: Int>")
    expect(subject.from_const(42).inspect).to eq("Value<42 :: Int>")
    expect(subject.from_const(1_000_000_000_000).inspect).to eq("Value<1000000000000 :: Int>")
    expect(subject.from_const(-1_000_000_000_000).inspect).to eq("Value<(- 1000000000000) :: Int>")
  end

  it "raises exception when trying to convert constants of wrong type" do
    expect{ subject.from_const(true) }.to raise_error(Z3::Exception)
    expect{ subject.from_const(false) }.to raise_error(Z3::Exception)
    expect{ subject.from_const(0.0) }.to raise_error(Z3::Exception)
  end

  it "can instantiate variables" do
    expect(Z3.Int("a").inspect).to eq("Value<a :: Int>")
  end
end
