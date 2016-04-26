describe Z3::BitvecSort do
  let(:bv3) { Z3::BitvecSort.new(3) }
  let(:bv8) { Z3::BitvecSort.new(8) }
  let(:bv32) { Z3::BitvecSort.new(32) }

  it "can instantiate constants" do
    expect(bv32.from_const(0).inspect).to eq("Value<#x00000000 :: Bitvec(32)>")
    expect(bv32.from_const(42).inspect).to eq("Value<#x0000002a :: Bitvec(32)>")
    expect(bv32.from_const(0x1234_5678_9abc).inspect).to eq("Value<#x56789abc :: Bitvec(32)>")
    expect(bv32.from_const(-0x1234_5678_9abc).inspect).to eq("Value<#xa9876544 :: Bitvec(32)>")

    expect(bv8.from_const(0).inspect).to eq("Value<#x00 :: Bitvec(8)>")
    expect(bv8.from_const(42).inspect).to eq("Value<#x2a :: Bitvec(8)>")
    expect(bv8.from_const(0x1234_5678_9abc).inspect).to eq("Value<#xbc :: Bitvec(8)>")
    expect(bv8.from_const(-0x1234_5678_9abc).inspect).to eq("Value<#x44 :: Bitvec(8)>")

    expect(bv3.from_const(-1).inspect).to eq("Value<#b111 :: Bitvec(3)>")
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
