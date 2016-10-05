module Z3
  describe RoundingModeSort do
    let(:sort) { RoundingModeSort.new }

    it "to_s" do
      expect(sort.to_s).to eq("RoundingMode")
    end

    it "inspect" do
      expect(sort.inspect).to eq("RoundingModeSort")
    end
  end
end
