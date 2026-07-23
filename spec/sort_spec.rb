module Z3
  describe Sort do
    let(:bool_sort) { BoolSort.new }
    let(:int_sort)  { IntSort.new }
    let(:real_sort) { RealSort.new }
    let(:bv8_sort)  { BitvecSort.new(8) }
    let(:bv32_sort) { BitvecSort.new(32) }

    let(:sorts) { [bool_sort, int_sort, real_sort, bv8_sort, bv32_sort] }

    it "can't instantiate Sort abstract superclass" do
      expect{ Sort.new }.to raise_error(NoMethodError)
    end

    it ".from_pointer rejects sort kinds the gem doesn't wrap" do
      uninterpreted = LowLevel.mk_uninterpreted_sort(LowLevel.mk_string_symbol("U"))
      expect{ Sort.from_pointer(uninterpreted) }.to raise_error(Z3::Exception, /Unknown sort kind/)
    end

    it "#to_s" do
      expect(bool_sort.to_s).to eq("Bool")
      expect( int_sort.to_s).to eq("Int")
      expect(real_sort.to_s).to eq("Real")
      expect( bv8_sort.to_s).to eq("Bitvec(8)")
      expect(bv32_sort.to_s).to eq("Bitvec(32)")
    end

    it "#inspect" do
      expect(bool_sort.inspect).to eq("BoolSort")
      expect( int_sort.inspect).to eq("IntSort")
      expect(real_sort.inspect).to eq("RealSort")
      expect( bv8_sort.inspect).to eq("BitvecSort(8)")
      expect(bv32_sort.inspect).to eq("BitvecSort(32)")
    end

    describe "==" do
      it "all Sorts are value-objects" do
        expect(bool_sort).to eq( BoolSort.new )
        expect( int_sort).to eq( IntSort.new )
        expect(real_sort).to eq( RealSort.new )
        expect( bv8_sort).to eq( BitvecSort.new(8) )
        expect(bv32_sort).to eq( BitvecSort.new(32) )
      end

      it "is == to itself and no other sort" do
        sorts.each do |sort1|
          sorts.each do |sort2|
            expect(sort1 == sort2).to eq(sort1.to_s == sort2.to_s)
          end
        end
      end
    end

    describe "#hash" do
      let(:array_of_bool) { ArraySort.new(IntSort.new, BoolSort.new) }
      let(:set_of_int)    { SetSort.new(IntSort.new) }

      it "matches eql? for every pair of sorts" do
        all = sorts + [set_of_int, array_of_bool, ArraySort.new(IntSort.new, IntSort.new),
                       FloatSort.new(:single), RoundingModeSort.new]
        all.each do |sort1|
          all.each do |sort2|
            # Ruby requires eql? objects to hash the same
            expect(sort1.hash == sort2.hash).to be true if sort1.eql?(sort2)
          end
        end
      end

      it "is equal for equal sorts" do
        expect(int_sort.hash).to eq(IntSort.new.hash)
        expect(bv8_sort.hash).to eq(BitvecSort.new(8).hash)
        expect(set_of_int.hash).to eq(SetSort.new(IntSort.new).hash)
      end

      it "differs for distinct sorts" do
        expect(sorts.map(&:hash).uniq.size).to eq(sorts.size)
        # These used to collide, as every sort hashed on its class alone
        expect(bv8_sort.hash).to_not eq(bv32_sort.hash)
        expect(FloatSort.new(:single).hash).to_not eq(FloatSort.new(:double).hash)
        expect(set_of_int.hash).to_not eq(SetSort.new(RealSort.new).hash)
      end

      # Z3 has no Set sort of its own, Set(X) is just Array(X, Bool)
      it "treats Set(X) and Array(X, Bool) as one sort, as Z3 does" do
        expect(array_of_bool).to eq(set_of_int)
        expect(array_of_bool.hash).to eq(set_of_int.hash)
        expect({array_of_bool => 1}[set_of_int]).to eq(1)
        expect([array_of_bool, set_of_int].uniq.size).to eq(1)
      end

      it "works as a Hash key" do
        counts = Hash.new(0)
        3.times { counts[IntSort.new] += 1 }
        counts[BitvecSort.new(8)] += 1
        expect(counts).to eq({IntSort.new => 3, BitvecSort.new(8) => 1})
      end
    end
  end
end
