module Z3
  describe TypeVariableSort do
    let(:sort) { TypeVariableSort.new("T") }

    it "to_s" do
      expect(sort.to_s).to eq("T")
    end

    it "inspect" do
      expect(sort.inspect).to eq("TypeVariableSort(T)")
    end

    it "is a value object" do
      expect(sort).to eq(TypeVariableSort.new("T"))
      expect(sort).to_not eq(TypeVariableSort.new("S"))
      # A type variable is not the uninterpreted sort of the same name
      expect(sort).to_not eq(UninterpretedSort.new("T"))
    end

    it "can instantiate variables" do
      expect(sort.var("t").inspect).to eq("T<t>")
    end
  end
end
