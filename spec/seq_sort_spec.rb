module Z3
  describe SeqSort do
    let(:int_seq)  { SeqSort.new(IntSort.new) }
    let(:bool_seq) { SeqSort.new(BoolSort.new) }
    let(:seq_seq)  { SeqSort.new(SeqSort.new(IntSort.new)) }

    it "to_s" do
      expect(int_seq.to_s).to eq("Seq(Int)")
      expect(bool_seq.to_s).to eq("Seq(Bool)")
      expect(seq_seq.to_s).to eq("Seq(Seq(Int))")
    end

    it "inspect" do
      expect(int_seq.inspect).to eq("SeqSort(Int)")
      expect(seq_seq.inspect).to eq("SeqSort(Seq(Int))")
    end

    it "element_sort" do
      expect(int_seq.element_sort).to eq(IntSort.new)
      expect(seq_seq.element_sort).to eq(int_seq)
    end

    it "is a value object" do
      expect(int_seq).to eq(SeqSort.new(IntSort.new))
      expect(int_seq).to_not eq(bool_seq)
    end

    it "can instantiate variables" do
      expect(int_seq.var("xs").inspect).to eq("Seq(Int)<xs>")
    end

    # Z3 has no String sort of its own, String is just Seq(Char)
    it "treats Seq(Char) and String as one sort, as Z3 does" do
      expect(SeqSort.new(CharSort.new)).to eq(StringSort.new)
      expect(SeqSort.new(CharSort.new).hash).to eq(StringSort.new.hash)
    end
  end
end
