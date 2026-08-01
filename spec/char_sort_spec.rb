module Z3
  describe CharSort do
    let(:sort) { CharSort.new }

    it "to_s" do
      expect(sort.to_s).to eq("Char")
    end

    it "inspect" do
      expect(sort.inspect).to eq("CharSort")
    end

    it "is a value object" do
      expect(sort).to eq(CharSort.new)
      expect(sort).to_not eq(StringSort.new)
    end

    it "can instantiate variables" do
      expect(sort.var("c").inspect).to eq("Char<c>")
    end
  end
end
