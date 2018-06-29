module Z3
  describe BitvecSort do
    let(:bv3) { BitvecSort.new(3) }
    let(:bv8) { BitvecSort.new(8) }
    let(:bv32) { BitvecSort.new(32) }

    it "can instantiate constants - 32 bit" do
      expect(bv32.from_const(0).inspect).to eq("Bitvec(32)<0>")
      expect(bv32.from_const(42).inspect).to eq("Bitvec(32)<42>")
      expect(bv32.from_const(0x1234_5678_9abc).inspect).to eq("Bitvec(32)<1450744508>")
      expect(bv32.from_const(-0x1234_5678_9abc).inspect).to eq("Bitvec(32)<2844222788>")
    end

    it "can instantiate constants - 8 bit" do
      expect(bv8.from_const(0).inspect).to eq("Bitvec(8)<0>")
      expect(bv8.from_const(42).inspect).to eq("Bitvec(8)<42>")
      expect(bv8.from_const(0x1234_5678_9abc).inspect).to eq("Bitvec(8)<188>")
      expect(bv8.from_const(-0x1234_5678_9abc).inspect).to eq("Bitvec(8)<68>")
    end

    it "can instantiate constants - 3 bit" do
      expect(bv3.from_const(-1).inspect).to eq("Bitvec(3)<7>")
    end

    it "raisesbv32 exception when trying to convert constants of wrong type" do
      expect{ bv32.from_const(true) }.to raise_error(Z3::Exception)
      expect{ bv32.from_const(false) }.to raise_error(Z3::Exception)
      expect{ bv32.from_const(0.0) }.to raise_error(Z3::Exception)
    end

    it "can instantiate variables" do
      expect(Z3.Bitvec("a", 8).inspect).to eq("Bitvec(8)<a>")
      expect(Z3.Bitvec("a", 32).inspect).to eq("Bitvec(32)<a>")
    end

    it "number of bits must be positive" do
      expect{ Z3.Bitvec("a", 0) }.to raise_error(Z3::Exception)
    end
  end
end
