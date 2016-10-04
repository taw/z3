module Z3
  describe FloatSort do
    let(:float_16)        { FloatSort.new(16) }
    let(:float_32)        { FloatSort.new(32) }
    let(:float_64)        { FloatSort.new(64) }
    let(:float_128)       { FloatSort.new(128) }
    let(:float_half)      { FloatSort.new(:half) }
    let(:float_single)    { FloatSort.new(:single) }
    let(:float_double)    { FloatSort.new(:double) }
    let(:float_quadruple) { FloatSort.new(:quadruple) }
    let(:float_5_11)      { FloatSort.new(5, 11) }
    let(:float_8_24)      { FloatSort.new(8, 24) }
    let(:float_11_53)     { FloatSort.new(11, 53) }
    let(:float_15_113)    { FloatSort.new(15, 113) }

    it "to_s" do
      expect(float_5_11.to_s).to eq("Float(5, 11)")
      expect(float_15_113.to_s).to eq("Float(15, 113)")
    end

    it "inspect" do
      expect(float_5_11.inspect).to eq("FloatSort(5, 11)")
      expect(float_15_113.inspect).to eq("FloatSort(15, 113)")
    end

    it "sbits" do
      expect(float_8_24.sbits).to eq(24)
      expect(float_11_53.sbits).to eq(53)
    end

    it "ebits" do
      expect(float_8_24.ebits).to eq(8)
      expect(float_11_53.ebits).to eq(11)
    end

    it "shortcut syntax" do
      expect(float_16).not_to eq(float_32)

      expect(float_16).to eq(float_half)
      expect(float_16).to eq(float_5_11)

      expect(float_32).to eq(float_single)
      expect(float_32).to eq(float_8_24)

      expect(float_64).to eq(float_double)
      expect(float_64).to eq(float_11_53)

      expect(float_128).to eq(float_quadruple)
      expect(float_128).to eq(float_15_113)
    end
  end
end
