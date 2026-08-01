module Z3
  describe StringSort do
    let(:sort) { StringSort.new }

    it "to_s" do
      expect(sort.to_s).to eq("String")
    end

    it "inspect" do
      expect(sort.inspect).to eq("StringSort")
    end

    it "is a value object" do
      expect(sort).to eq(StringSort.new)
      expect(sort).to_not eq(SeqSort.new(IntSort.new))
    end

    it "can instantiate variables" do
      expect(sort.var("s").inspect).to eq("String<s>")
    end
  end
end
