module Z3
  describe ReSort do
    let(:string_re) { ReSort.new(StringSort.new) }
    let(:int_seq_re) { ReSort.new(SeqSort.new(IntSort.new)) }

    it "to_s" do
      expect(string_re.to_s).to eq("Re(String)")
      expect(int_seq_re.to_s).to eq("Re(Seq(Int))")
    end

    it "inspect" do
      expect(string_re.inspect).to eq("ReSort(String)")
      expect(int_seq_re.inspect).to eq("ReSort(Seq(Int))")
    end

    it "seq_sort" do
      expect(string_re.seq_sort).to eq(StringSort.new)
      expect(int_seq_re.seq_sort).to eq(SeqSort.new(IntSort.new))
    end

    it "is a value object" do
      expect(string_re).to eq(ReSort.new(StringSort.new))
      expect(string_re).to_not eq(int_seq_re)
    end

    it "can instantiate variables" do
      expect(string_re.var("r").inspect).to eq("Re(String)<r>")
    end
  end
end
