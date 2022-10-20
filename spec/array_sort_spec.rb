module Z3
  describe ArraySort do
    let(:int_int_array)  { ArraySort.new(IntSort.new, IntSort.new) }
    let(:int_real_array) { ArraySort.new(IntSort.new, RealSort.new) }

    it "can instantiate variables" do
      expect(int_int_array.var("a").inspect).to eq("Array(Int, Int)<a>")
      expect(int_real_array.var("a").inspect).to eq("Array(Int, Real)<a>")
    end
  end
end
