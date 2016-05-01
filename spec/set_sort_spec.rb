module Z3
  describe SetSort do

    let(:int_set)     { SetSort.new(IntSort.new) }
    let(:real_set)    { SetSort.new(RealSort.new) }
    let(:bool_set)    { SetSort.new(BoolSort.new) }
    let(:bv32_set)    { SetSort.new(BitvecSort.new(32)) }
    let(:int_set_set) { SetSort.new(SetSort.new(IntSort.new)) }

    it "can instantiate variables" do
      expect(int_set.var("a").inspect).to eq("Set(Int)<a>")
      expect(real_set.var("a").inspect).to eq("Set(Real)<a>")
      expect(bool_set.var("a").inspect).to eq("Set(Bool)<a>")
      expect(bv32_set.var("a").inspect).to eq("Set(Bitvec(32))<a>")
      expect(int_set_set.var("a").inspect).to eq("Set(Set(Int))<a>")
    end
  end
end
