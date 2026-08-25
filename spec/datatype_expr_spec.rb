module Z3
  describe DatatypeExpr do
    let(:int) { IntSort.new }
    let(:sort) { DatatypeSort.new("Lst", nil: [], cons: {head: int, tail: :self}) }
    let(:l) { sort.var("l") }

    it "inspect" do
      expect(l.inspect).to eq("Lst<l>")
      expect(sort[cons: {head: 3, tail: :nil}].inspect).to eq("Lst<cons(3, nil)>")
    end

    it "to_s" do
      expect(sort[cons: {head: 3, tail: :nil}]).to stringify("cons(3, nil)")
      expect(l.head).to stringify("l.head")
      expect(l.tail.head).to stringify("l.tail.head")
      expect(l.is_nil).to stringify("l.is_nil")
      expect(l.head + 1).to stringify("l.head + 1")
      expect(l == sort[:nil]).to stringify("l = nil")
    end

    describe "recognizers" do
      it "reads as a method per constructor" do
        expect(l.is_nil).to be_a(BoolExpr)
        expect(l.is_cons).to be_equivalent_to(~l.is_nil)
      end

      it "also reads with #is?" do
        expect(l.is?(:nil)).to eq(l.is_nil)
        expect(l.is?("cons")).to eq(l.is_cons)
      end

      # `nil?` would be the natural Ruby spelling, and taking it over would make every
      # value of the sort look like Ruby's nil to everything which asks
      it "leaves nil? alone" do
        expect(l.nil?).to eq(false)
        expect(l.is_nil).to be_a(BoolExpr)
      end

      it "defines the ? spelling where the name is free" do
        option = DatatypeSort.new("Opt", none: [], some: {some_v: int})
        o = option.var("o")
        expect(o.some?).to eq(o.is_some)
        expect(o.none?).to eq(o.is_none)
      end
    end

    describe "fields" do
      it "reads as a method per field" do
        expect(l.head.sort).to eq(int)
        expect(l.tail.sort).to eq(sort)
      end

      it "reads with #[] as well" do
        expect(l[:head]).to eq(l.head)
        expect(l["tail"]).to eq(l.tail)
      end

      # Accessors are total on Z3's side - `nil.head` is some Int, Z3 just won't say
      # which, and nothing about that is an error
      it "is total" do
        expect([sort[:nil].head == 7]).to have_solution({})
      end

      it "raises for a field which isn't there" do
        expect{ l[:rest] }
          .to raise_error(Z3::Exception, "Lst has no field :rest, only :head, :tail")
      end

      # Same rule as a tuple's fields - a field named after something an expression
      # already answers to keeps the expression's method, and #[] reads the field
      it "doesn't take over a method Expr already has" do
        shadow = DatatypeSort.new("Shadow", empty: [], full: {sort: int, value: int})
        s = shadow.var("s")
        expect(s.sort).to eq(shadow)
        expect(s[:sort].sort).to eq(int)
        expect(s[:value].sort).to eq(int)
      end
    end

    describe "#value" do
      it "is a Symbol for a constructor with no fields" do
        expect(sort[:nil].value).to eq(:nil)
      end

      it "is a constructor pointing at its fields otherwise" do
        expect(sort[cons: {head: 3, tail: :nil}].value).to eq({cons: {head: 3, tail: :nil}})
      end

      it "nests" do
        expect(sort[cons: {head: 1, tail: {cons: {head: 2, tail: :nil}}}].value)
          .to eq({cons: {head: 1, tail: {cons: {head: 2, tail: :nil}}}})
      end

      # Which is the whole point of the shape - it goes straight back in
      it "round-trips through #from_const" do
        value = {cons: {head: 1, tail: {cons: {head: 2, tail: :nil}}}}
        expect(sort[value].value).to eq(value)
      end

      it "raises for a term which isn't built from the constructors" do
        expect{ l.value }
          .to raise_error(Z3::Exception, "Can't convert l into a Ruby value, it isn't built from Lst's constructors")
      end

      # Same reasoning as TupleExpr#value - a field sort with no #value stops the
      # whole conversion, and saying which field is the useful part
      it "raises for a field sort with no #value" do
        no_value = DatatypeSort.new("NoValue", empty: [], real: {r: RealSort.new})
        expect{ no_value[real: {r: 1}].value }
          .to raise_error(Z3::Exception, "Can't convert NoValue into a Ruby value, field :r is Real, which has no #value")
      end
    end

    describe "solving" do
      it "reads a value out of a model" do
        v = sort.var("model_l")
        solver = Solver.new
        solver.assert v.is_cons
        solver.assert v.head == 5
        solver.assert v.tail.is_cons
        solver.assert v.tail.head == 6
        solver.assert v.tail.tail.is_nil
        solver.check
        expect(solver.model[v].value).to eq({cons: {head: 5, tail: {cons: {head: 6, tail: :nil}}}})
      end

      # The reason to have datatypes at all: a recursive function over one, proved by
      # structural induction with Z3 discharging each case
      it "proves a theorem by structural induction" do
        proof_sort = DatatypeSort.new("ProofLst", pnil: [], pcons: {phead: int, ptail: :self})
        len = Z3.RecFunction("plen", proof_sort, int) do |len, xs|
          Z3.IfThenElse(xs.is_pnil, 0, 1 + len[xs.ptail])
        end
        solver = Solver.new

        # base: len(nil) >= 0
        solver.push
        solver.assert ~(len[proof_sort[:pnil]] >= 0)
        expect(solver.check).to eq(:unsat)
        solver.pop

        # step: len(xs) >= 0 => len(cons(x, xs)) >= 0
        solver.push
        xs = proof_sort.var("xs")
        solver.assert len[xs] >= 0
        solver.assert ~(len[proof_sort.mk(:pcons, Z3.Int("x"), xs)] >= 0)
        expect(solver.check).to eq(:unsat)
        solver.pop
      end
    end
  end
end
