module Z3
  describe FiniteDomainSort do
    let(:sort) { FiniteDomainSort.new("FD", 3) }

    it "to_s" do
      expect(sort.to_s).to eq("FD")
    end

    it "inspect" do
      expect(sort.inspect).to eq("FiniteDomainSort(FD, 3)")
    end

    it "size" do
      expect(sort.size).to eq(3)
      expect(FiniteDomainSort.new("Big", 2**40).size).to eq(2**40)
    end

    it "is a value object" do
      expect(sort).to eq(FiniteDomainSort.new("FD", 3))
      # Same name but different size is a different sort to Z3
      expect(sort).to_not eq(FiniteDomainSort.new("FD", 4))
      expect(sort).to_not eq(FiniteDomainSort.new("Other", 3))
    end

    it "can instantiate variables" do
      expect(sort.var("x").inspect).to eq("FD<x>")
    end

    describe "#from_const" do
      it "builds a value out of a Ruby Integer" do
        expect(sort.from_const(2)).to be_a(FiniteDomainExpr)
        expect(sort.from_const(2).sort).to eq(sort)
        expect(sort.from_const(2).to_s).to eq("2")
      end

      # The values are 0 to size - 1, and Z3 gives them no names of their own
      it "round trips through #value" do
        expect((0...3).map { |i| sort.from_const(i).value }).to eq([0, 1, 2])
        big = FiniteDomainSort.new("Big", 2**40)
        expect(big.from_const(2**40 - 1).value).to eq(2**40 - 1)
      end

      it "raises out of range, saying what the range was" do
        expect { sort.from_const(3) }.to raise_error(Z3::Exception, "FD value must be between 0 and 2")
        expect { sort.from_const(-1) }.to raise_error(Z3::Exception, "FD value must be between 0 and 2")
      end

      it "raises on anything which isn't an Integer" do
        expect { sort.from_const("2") }.to raise_error(Z3::Exception, "Can't convert String into FD")
        expect { sort.from_const(2.0) }.to raise_error(Z3::Exception, "Can't convert Float into FD")
        expect { sort.from_const(nil) }.to raise_error(Z3::Exception, "Can't convert nil into FD")
      end

      it "is what #cast goes through" do
        expect(sort.cast(2)).to be_same_as(sort.from_const(2))
        expect(sort.cast(sort.from_const(2))).to be_same_as(sort.from_const(2))
      end

      # A Ruby Integer means an Int everywhere else, so unlike a Bitvec it isn't
      # coerced into this sort - values have to be asked for by name
      it "is how a value gets into an expression, a bare Integer being a sort mismatch" do
        x = sort.var("x")
        expect([x == sort.from_const(1)]).to have_solution(x => sort.from_const(1))
        expect([Z3.Distinct(x, sort.from_const(1))]).to have_solution(x => sort.from_const(0))
        expect { x == 1 }.to raise_error(ArgumentError, "Can't convert Int into FD")
      end
    end

    it "size must be a positive Integer" do
      expect{ FiniteDomainSort.new("FD", 0) }.to raise_error(Z3::Exception)
      expect{ FiniteDomainSort.new("FD", -3) }.to raise_error(Z3::Exception)
      expect{ FiniteDomainSort.new("FD", 3.9) }.to raise_error(Z3::Exception)
      expect{ FiniteDomainSort.new("FD", "3") }.to raise_error(Z3::Exception)
    end
  end
end
