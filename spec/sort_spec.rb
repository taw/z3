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
  end
end
