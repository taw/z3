module Z3
  describe FiniteDomainSort do
    let(:sort) { FiniteDomainSort.new("FD", 3) }

    it "to_s" do
      expect(sort.to_s).to eq("FD")
    end

    it "inspect" do
      expect(sort.inspect).to eq("FiniteDomainSort(FD, 3)")
    end

    it "size" do
      expect(sort.size).to eq(3)
      expect(FiniteDomainSort.new("Big", 2**40).size).to eq(2**40)
    end

    it "is a value object" do
      expect(sort).to eq(FiniteDomainSort.new("FD", 3))
      # Same name but different size is a different sort to Z3
      expect(sort).to_not eq(FiniteDomainSort.new("FD", 4))
      expect(sort).to_not eq(FiniteDomainSort.new("Other", 3))
    end

    it "can instantiate variables" do
      expect(sort.var("x").inspect).to eq("FD<x>")
    end

    it "size must be a positive Integer" do
      expect{ FiniteDomainSort.new("FD", 0) }.to raise_error(Z3::Exception)
      expect{ FiniteDomainSort.new("FD", -3) }.to raise_error(Z3::Exception)
      expect{ FiniteDomainSort.new("FD", 3.9) }.to raise_error(Z3::Exception)
      expect{ FiniteDomainSort.new("FD", "3") }.to raise_error(Z3::Exception)
    end
  end
end
