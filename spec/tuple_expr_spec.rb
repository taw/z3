module Z3
  describe TupleExpr do
    let(:int) { IntSort.new }
    let(:sort) { TupleSort.new("Pt", x: int, y: int) }
    let(:p) { sort.var("p") }

    it "inspect" do
      expect(p.inspect).to eq("Pt<p>")
      expect(sort.mk(3, 4).inspect).to eq("Pt<Pt.mk(3, 4)>")
    end

    it "to_s" do
      expect(sort.mk(3, 4)).to stringify("Pt.mk(3, 4)")
      expect(p.x).to stringify("p.x")
      expect(p.x + 1).to stringify("p.x + 1")
      expect(sort.mk(3, 4).y).to stringify("Pt.mk(3, 4).y")
      expect((p == sort.mk(3, 4))).to stringify("p = Pt.mk(3, 4)")
    end

    describe "fields" do
      it "reads as a method" do
        expect(p.x.sort).to eq(int)
        expect(p.x).to eq(sort.accessor(:x)[p])
      end

      it "reads with #[]" do
        expect(p[:x]).to eq(p.x)
        expect(p["x"]).to eq(p.x)
      end

      it "keeps their own sorts" do
        mixed = TupleSort.new("Mixed", i: int, b: BoolSort.new, s: StringSort.new)
        m = mixed.var("m")
        expect(m.i.sort).to eq(int)
        expect(m.b.sort).to eq(BoolSort.new)
        expect(m.s.sort).to eq(StringSort.new)
        expect(m.b & true).to stringify("and(m.b, true)")
      end

      it "raises for a field which doesn't exist" do
        expect{ p[:z] }.to raise_error(Z3::Exception, "Pt has no field :z, only :x, :y")
        expect{ p.z }.to raise_error(NoMethodError, /undefined method [`']z' for an instance of Z3::TupleExpr\(Pt\)/)
      end

      # Every tuple sort gets an expr class of its own to hang the field readers on,
      # so two tuples with a field of the same name don't collide
      it "belong to one tuple sort only" do
        other = TupleSort.new("OtherPt", x: StringSort.new)
        expect(other.var("o").x.sort).to eq(StringSort.new)
        expect(p.x.sort).to eq(int)
        expect{ other.var("o")[:y] }.to raise_error(Z3::Exception, "OtherPt has no field :y, only :x")
      end

      # Taking these over would break the expression itself, and #[] reads them anyway
      it "don't shadow what Expr already answers to" do
        shadowing = TupleSort.new("Shadowing", sort: int, value: int, to_s: int, ok: int)
        s = shadowing.var("s")
        expect(s.sort).to be(shadowing)
        expect(s.to_s).to eq("s")
        expect(shadowing.mk(1, 2, 3, 4).value).to eq({sort: 1, value: 2, to_s: 3, ok: 4})
        expect(s[:sort]).to stringify("s.sort")
        expect(s[:to_s]).to stringify("s.to_s")
        expect(s.ok).to stringify("s.ok")
      end
    end

    describe "#==" do
      it "casts an Array or a Hash to the tuple on the other side" do
        expect(p == [3, 4]).to eq(p == sort.mk(3, 4))
        expect(p == {x: 3, y: 4}).to eq(p == sort.mk(3, 4))
        expect(p != [3, 4]).to stringify("distinct(p, Pt.mk(3, 4))")
      end

      it "raises for an Array which isn't the right shape" do
        expect{ p == [3] }.to raise_error(Z3::Exception, "Pt has 2 fields, got 1 argument")
        expect{ p == {x: 3} }.to raise_error(Z3::Exception, "Pt needs a value for field :y")
      end

      # An Array is only a tuple when there's a tuple on the other side of the
      # operation - there's nothing else it could be a value of
      it "has no sort of its own" do
        expect{ Z3.Const([3, 4]) }.to raise_error(Z3::Exception, "No Z3 sort for Array")
        expect{ Z3.Int("i") == [3, 4] }.to raise_error(Z3::Exception, "Array can't be coerced into Int")
      end
    end

    describe "#value" do
      it "returns a Hash of the fields" do
        expect(sort.mk(3, 4).value).to eq({x: 3, y: 4})
      end

      it "simplifies first, like every other #value" do
        expect(Z3.IfThenElse(Z3.Const(true), sort.mk(3, 4), sort.mk(5, 6)).value).to eq({x: 3, y: 4})
      end

      it "converts each field to its own kind of Ruby value" do
        mixed = TupleSort.new("MixedValue", i: int, b: BoolSort.new, s: StringSort.new)
        expect(mixed.mk(1, true, "hi").value).to eq({i: 1, b: true, s: "hi"})
      end

      it "recurses into nested tuples" do
        nested = TupleSort.new("Nested", inner: sort, n: int)
        expect(nested.mk(sort.mk(3, 4), 5).value).to eq({inner: {x: 3, y: 4}, n: 5})
      end

      it "raises for anything which isn't a value" do
        expect{ p.value }.to raise_error(Z3::Exception, "Can't convert expression p.x into Integer")
      end

      # Real and Bitvec have no #value of their own, and a NoMethodError from inside
      # the Hash wouldn't say which field it came from
      it "raises for a field sort which has no #value" do
        real = TupleSort.new("RealValue", r: RealSort.new)
        expect{ real.mk(1).value }
          .to raise_error(Z3::Exception, "Can't convert RealValue into a Hash, field :r is Real, which has no #value")
      end

      it "comes back from a model" do
        solver = Solver.new
        solver.assert p.x == 3
        solver.assert p.y == p.x * 2
        expect(solver.check).to eq(:sat)
        expect(solver.model[p].value).to eq({x: 3, y: 6})
      end
    end
  end
end
