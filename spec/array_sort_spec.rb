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
        expect(bool_array.Const(false)).to eql(set.Empty)
        expect(bool_array.Const(true)).to eql(set.Full)
      end
    end

    # Z3 has one sort here, so the gem has one class for it - the same redirect
    # SeqSort does for Seq(Char), which is a String. Without it the same Z3 term
    # arrives as an ArrayExpr or a SetExpr depending on where it came from, and
    # AST#eql? compares class while #hash doesn't, so the two break as Hash keys.
    describe "Array(X, Bool) is a Set(X)" do
      let(:bool_array) { ArraySort.new(IntSort.new, BoolSort.new) }

      it "is a SetSort, not an ArraySort" do
        expect(bool_array).to be_a(SetSort)
        expect(bool_array).to_not be_a(ArraySort)
        expect(bool_array.to_s).to eq("Set(Int)")
        expect(bool_array).to eq(SetSort.new(IntSort.new))
      end

      it "makes SetExprs" do
        expect(bool_array.var("v")).to be_a(SetExpr)
        expect(bool_array.var("v").inspect).to eq("Set(Int)<v>")
      end

      it "applies to any value sort that is Bool, however nested" do
        expect(ArraySort.new(BoolSort.new, BoolSort.new).to_s).to eq("Set(Bool)")
        expect(ArraySort.new(IntSort.new, ArraySort.new(IntSort.new, BoolSort.new)).to_s)
          .to eq("Array(Int, Set(Int))")
      end

      # A one argument Bool-valued lambda is exactly a set, and used to be the one
      # place the gem built an Array(X, Bool) behind your back
      it "covers Z3.Lambda with a Bool body" do
        x = Z3.Int("x")
        lambda = Z3.Lambda(x, x > 0)
        expect(lambda).to be_a(SetExpr)
        expect(lambda.sort.to_s).to eq("Set(Int)")
      end

      it "agrees with what Sort.from_pointer builds, so one term is one class" do
        x = Z3.Int("x")
        built = Z3.Lambda(x, x > 0)
        read_back = Expr.new_from_pointer(LowLevel.mk_lambda_const([x], x > 0))
        expect(built.class).to eq(read_back.class)
        expect(built).to eql(read_back)
        expect(built.hash).to eq(read_back.hash)
        expect({built => "found"}[read_back]).to eq("found")
      end

      # The redirect must not quietly remove methods
      it "still answers the whole ArraySort/ArrayExpr vocabulary" do
        v = bool_array.var("v")
        expect(bool_array.key_sort).to eq(IntSort.new)
        expect(bool_array.value_sort).to eq(BoolSort.new)
        expect(v.key_sort).to eq(IntSort.new)
        expect(v.value_sort).to eq(BoolSort.new)
        expect(v.default.sort).to eq(BoolSort.new)
        expect(v[3]).to eql(v.include?(3))
        expect(v.store(3, true)).to eql(v.add(3))
        expect(v.store(3, false)).to eql(v.delete(3))
        # #store is the only one of these that takes a symbolic Bool
        expect(v.store(3, Z3.Bool("b")).sort.to_s).to eq("Set(Int)")
      end
    end
  end
end
