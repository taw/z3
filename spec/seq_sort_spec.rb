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

    it "can instantiate constants" do
      expect(int_seq.from_const([]).inspect).to eq("Seq(Int)<[]>")
      expect(int_seq.from_const([42]).inspect).to eq("Seq(Int)<[42]>")
      expect(int_seq.from_const([1, -2, 3]).inspect).to eq("Seq(Int)<[1, -2, 3]>")
      expect(bool_seq.from_const([true, false]).inspect).to eq("Seq(Bool)<[true, false]>")
      expect(seq_seq.from_const([[1], []]).inspect).to eq("Seq(Seq(Int))<[[1], []]>")
      expect(SeqSort.new(StringSort.new).from_const(["ab", "c"]).inspect).to eq(%q{Seq(String)<["ab", "c"]>})
    end

    it "can instantiate constants out of exprs" do
      expect(int_seq.from_const([1, Z3.Int("x")]).inspect).to eq("Seq(Int)<[1, x]>")
    end

    it "raises exception when trying to convert constants of wrong type" do
      expect{ int_seq.from_const("abc") }.to raise_error(Z3::Exception)
      expect{ int_seq.from_const(nil) }.to raise_error(Z3::Exception)
      expect{ int_seq.from_const(42) }.to raise_error(Z3::Exception)
      expect{ int_seq.from_const([1, "x"]) }.to raise_error(Z3::Exception)
    end

    it "values can be used in constraints" do
      xs = int_seq.var("xs")
      expect([xs == int_seq.from_const([3, 1, 4])]).to have_solution(xs => "[3, 1, 4]")
    end

    # Z3 has no String sort of its own, String is just Seq(Char)
    it "treats Seq(Char) and String as one sort, as Z3 does" do
      expect(SeqSort.new(CharSort.new)).to eq(StringSort.new)
      expect(SeqSort.new(CharSort.new).hash).to eq(StringSort.new.hash)
      # And it's not just equal, it is a StringSort - one Z3 sort, one Ruby class
      expect(SeqSort.new(CharSort.new).class).to eq(StringSort)
      expect(SeqSort.new(CharSort.new).from_const("hi").inspect).to eq(%q{String<"hi">})
    end

    # ...by every route that builds one, not just the constructor
    it "gives a String however the Seq(Char) got built" do
      expect(SeqSort.new(CharSort.new).var("s")).to be_a(StringExpr)
      expect(SeqExpr.Unit(CharSort.new.from_const("a"))).to be_a(StringExpr)
      expect(Expr.new_from_pointer(LowLevel.mk_string("hi"))).to be_a(StringExpr)
      # Nested, where only the inner sort is the Seq(Char)
      expect(SeqSort.new(SeqSort.new(CharSort.new)).to_s).to eq("Seq(String)")
      expect(ReSort.new(SeqSort.new(CharSort.new)).to_s).to eq("Re(String)")
      # A Set of Char is an Array(Char, Bool), not a Seq, so it stays a Set
      expect(SetSort.new(CharSort.new).to_s).to eq("Set(Char)")
    end
  end
end
