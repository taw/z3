module Z3
  describe ArraySort do
    let(:int_int_array)  { ArraySort.new(IntSort.new, IntSort.new) }
    let(:int_real_array) { ArraySort.new(IntSort.new, RealSort.new) }

    it "can instantiate variables" do
      expect(int_int_array.var("a").inspect).to eq("Array(Int, Int)<a>")
      expect(int_real_array.var("a").inspect).to eq("Array(Int, Real)<a>")
    end

    describe "#Const" do
      let(:zeros) { int_int_array.Const(0) }

      it "maps every key to the same value" do
        expect(zeros.inspect).to eq("Array(Int, Int)<const(0)>")
        expect([zeros[7] != 0]).to have_no_solution
        expect([zeros[Z3.Int("k")] != 0]).to have_no_solution
      end

      it "casts the value into the array's value sort" do
        expect(int_real_array.Const(1).to_s).to eq("const(1)")
        expect{ int_int_array.Const("nope") }
          .to raise_error(Z3::Exception, "Can't convert String into Int")
      end

      # A Set is an Array with a Bool value sort, so Empty and Full are this already
      it "agrees with SetSort#Empty and #Full" do
        bool_array = ArraySort.new(IntSort.new, BoolSort.new)
        set = SetSort.new(IntSort.new)
        expect(bool_array.Const(false).to_s).to eq(set.Empty.to_s)
        expect(bool_array.Const(true).to_s).to eq(set.Full.to_s)
      end
    end
  end
end
