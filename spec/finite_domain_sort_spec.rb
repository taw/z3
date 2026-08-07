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

      it "is how a value gets into an expression" do
        x = sort.var("x")
        expect([x == sort.from_const(1)]).to have_solution(x => sort.from_const(1))
        expect([Z3.Distinct(x, sort.from_const(1))]).to have_solution(x => sort.from_const(0))
      end
    end

    # `FiniteDomainSort#>` claiming Int is what routes the literal here, the same way
    # BitvecSort does it
    describe "Ruby Integers in expressions" do
      let(:x) { sort.var("x") }

      it "coerces a bare Integer on either side" do
        expect([x == 1]).to have_solution(x => sort.from_const(1))
        expect([1 == x]).to have_solution(x => sort.from_const(1))
        expect([x != 1, x != 2]).to have_solution(x => sort.from_const(0))
        expect([Z3.Distinct(x, 1, 2)]).to have_solution(x => sort.from_const(0))
      end

      it "builds the same term as spelling the value out" do
        expect(x == 1).to be_same_as(x == sort.from_const(1))
      end

      # from_const's range check, which a Bitvec can't have - `bv == -1` and
      # `bv == 255` both have to work at width 8, so there's no range to enforce
      it "raises out of range rather than wrapping" do
        expect { x == 3 }.to raise_error(Z3::Exception, "FD value must be between 0 and 2")
        expect { x == -1 }.to raise_error(Z3::Exception, "FD value must be between 0 and 2")
      end

      # The claim only reaches Ruby values - from_value isn't overridden, so an Expr
      # of another sort is refused as it always was
      it "still refuses exprs of other sorts" do
        expect { x == Z3.Int("i") }.to raise_error(Z3::Exception, "Can't convert Int into FD")
        expect { Z3.Int("i") == x }.to raise_error(Z3::Exception, "Can't convert Int into FD")
        expect { Z3.Int("i") + x }.to raise_error(Z3::Exception, "Can't convert Int into FD")
        expect { x == Z3.Real("r") }.to raise_error(ArgumentError, "Can't convert Real into FD")
        expect { x == Z3.Bool("b") }.to raise_error(ArgumentError, "Can't convert Bool into FD")
        expect { x == 1.5 }.to raise_error(ArgumentError, "Can't convert Real into FD")
      end

      it "orders the sorts to match" do
        expect(sort > IntSort.new).to eq(true)
        expect(IntSort.new < sort).to eq(true)
        expect(sort <=> RealSort.new).to eq(nil)
        expect(sort <=> FiniteDomainSort.new("Other", 3)).to eq(nil)
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
