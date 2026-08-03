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

    # There's no regex literal, so the only thing that converts is a sequence -
    # `seq.to_re`, the regex matching exactly that one value
    describe "#from_const" do
      it "converts through the basis sort" do
        expect(string_re.from_const("ab").sexpr).to eq(%q{(str.to_re "ab")})
        expect(int_seq_re.from_const([1]).sexpr).to eq("(seq.to.re (seq.unit 1))")
      end

      it "rejects what the basis sort rejects" do
        expect { string_re.from_const(42) }.to raise_error(Z3::Exception)
        expect { int_seq_re.from_const("ab") }.to raise_error(Z3::Exception)
      end
    end

    describe "#from_value" do
      it "converts a sequence of the basis sort" do
        expect(string_re.cast(Z3.String("s")).sexpr).to eq("(str.to_re s)")
        expect(int_seq_re.cast(SeqSort.new(IntSort.new).var("xs")).sexpr).to eq("(seq.to.re xs)")
      end

      it "leaves a Re of its own sort alone" do
        re = string_re.from_const("ab")
        expect(string_re.cast(re)).to be_same_as(re)
      end

      it "rejects anything else" do
        expect { string_re.cast(Z3.Int("i")) }.to raise_error(Z3::Exception)
        expect { string_re.cast(int_seq_re.from_const([1])) }.to raise_error(Z3::Exception)
      end
    end

    describe "constants" do
      it "empty, full, and all_char" do
        expect(string_re.empty.sexpr).to eq("re.none")
        expect(string_re.full.sexpr).to eq("re.all")
        expect(string_re.all_char.sexpr).to eq("re.allchar")
      end

      it "carry the sort they were asked for" do
        expect(int_seq_re.full.sort).to eq(int_seq_re)
        expect(int_seq_re.all_char.sort).to eq(int_seq_re)
      end
    end
  end
end
