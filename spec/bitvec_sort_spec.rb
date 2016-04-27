describe Z3::BitvecSort do
  let(:bv3) { Z3::BitvecSort.new(3) }
  let(:bv8) { Z3::BitvecSort.new(8) }
  let(:bv32) { Z3::BitvecSort.new(32) }

  it "can instantiate constants - 32 bit" do
    expect(bv32.from_const(0).inspect).to eq("Value<0 :: Bitvec(32)>")
    expect(bv32.from_const(42).inspect).to eq("Value<42 :: Bitvec(32)>")
    expect(bv32.from_const(0x1234_5678_9abc).inspect).to eq("Value<1450744508 :: Bitvec(32)>")
    expect(bv32.from_const(-0x1234_5678_9abc).inspect).to eq("Value<2844222788 :: Bitvec(32)>")
  end

  it "can instantiate constants - 8 bit" do
    expect(bv8.from_const(0).inspect).to eq("Value<0 :: Bitvec(8)>")
    expect(bv8.from_const(42).inspect).to eq("Value<42 :: Bitvec(8)>")
    expect(bv8.from_const(0x1234_5678_9abc).inspect).to eq("Value<188 :: Bitvec(8)>")
    expect(bv8.from_const(-0x1234_5678_9abc).inspect).to eq("Value<68 :: Bitvec(8)>")
  end

  it "can instantiate constants - 3 bit" do
    expect(bv3.from_const(-1).inspect).to eq("Value<7 :: Bitvec(3)>")
  end

  it "raisesbv32 exception when trying to convert constants of wrong type" do
    expect{ bv32.from_const(true) }.to raise_error(Z3::Exception)
    expect{ bv32.from_const(false) }.to raise_error(Z3::Exception)
    expect{ bv32.from_const(0.0) }.to raise_error(Z3::Exception)
  end

  it "can instantiate variables" do
    expect(Z3.Bitvec("a", 8).inspect).to eq("Value<a :: Bitvec(8)>")
    expect(Z3.Bitvec("a", 32).inspect).to eq("Value<a :: Bitvec(32)>")
  end
end
