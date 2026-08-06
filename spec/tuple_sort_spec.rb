module Z3
  describe TupleSort do
    let(:int) { IntSort.new }
    let(:sort) { TupleSort.new("Point", x: int, y: int) }

    it "to_s" do
      expect(sort.to_s).to eq("Point")
    end

    it "inspect" do
      expect(sort.inspect).to eq("TupleSort(Point, x: Int, y: Int)")
    end

    it "fields" do
      expect(sort.fields).to eq({x: int, y: int})
    end

    it "can instantiate variables" do
      expect(sort.var("p").inspect).to eq("Point<p>")
      expect(sort.var(%w[p q]).map(&:inspect)).to eq(["Point<p>", "Point<q>"])
    end

    describe "#mk" do
      it "builds values" do
        expect(sort.mk(3, 4)).to stringify("Point.mk(3, 4)")
        expect(sort.mk(3, 4).sort).to eq(sort)
      end

      it "casts arguments to the field sorts" do
        real = TupleSort.new("MkCast", i: int, r: RealSort.new)
        expect(real.mk(1, 2)).to stringify("MkCast.mk(1, 2)")
        expect(real.mk(1, 2)[:r].sort).to eq(RealSort.new)
      end

      it "takes expressions too" do
        expect(sort.mk(Z3.Int("a"), 4)).to stringify("Point.mk(a, 4)")
      end

      it "raises for the wrong number of fields" do
        expect{ sort.mk(1) }.to raise_error(Z3::Exception, "Point has 2 fields, got 1 argument")
        expect{ sort.mk(1, 2, 3) }.to raise_error(Z3::Exception, "Point has 2 fields, got 3 arguments")
      end

      # Which field it was is the whole message here - a tuple can have several fields
      # of the same sort, and "Can't convert true into Int" alone names none of them
      it "raises for a value of the wrong sort, saying which field" do
        expect{ sort.mk(1, true) }.to raise_error(Z3::Exception, "Point field :y: Can't convert true into Int")
        expect{ sort.mk(BoolSort.new.var("b"), 2) }.to raise_error(Z3::Exception, "Point field :x: Can't convert Bool into Int")
      end
    end

    describe "#from_const" do
      it "takes the fields in order" do
        expect(sort.from_const([3, 4])).to stringify("Point.mk(3, 4)")
      end

      it "takes them by name" do
        expect(sort.from_const(y: 4, x: 3)).to stringify("Point.mk(3, 4)")
        expect(sort.from_const("x" => 3, "y" => 4)).to stringify("Point.mk(3, 4)")
      end

      it "raises for a Hash which doesn't name every field" do
        expect{ sort.from_const(x: 3) }.to raise_error(Z3::Exception, "Point needs a value for field :y")
      end

      # A Hash is the spelling where a typo in a field name is possible at all, and
      # an ignored key would build a value with a default nobody asked for
      it "raises for a Hash naming a field which doesn't exist" do
        expect{ sort.from_const(x: 3, y: 4, z: 5) }.to raise_error(Z3::Exception, "Point has no field :z")
        expect{ sort.from_const(x: 3, z: 5) }.to raise_error(Z3::Exception, "Point has no field :z")
      end

      it "raises for anything else" do
        expect{ sort.from_const(42) }.to raise_error(Z3::Exception, "Can't convert Integer into Point")
        expect{ sort.from_const(nil) }.to raise_error(Z3::Exception, "Can't convert nil into Point")
      end
    end

    describe "#accessor" do
      it "gives the decl behind a field" do
        expect(sort.accessor(:x).inspect).to eq("Z3::FuncDecl<x/1>")
        expect(sort.accessor("x")).to eq(sort.accessor(:x))
        expect(sort.accessor(:x)[sort.mk(3, 4)]).to stringify("Point.mk(3, 4).x")
      end

      it "raises for a field which doesn't exist" do
        expect{ sort.accessor(:z) }.to raise_error(Z3::Exception, "Point has no field :z, only :x, :y")
        expect{ sort.accessor(42) }.to raise_error(Z3::Exception, "Point has no field 42, only :x, :y")
      end
    end

    # Z3 gives back the sort it already has for a name, but rebuilds its constructor
    # and accessors from whatever fields it was passed this time - so unlike an enum,
    # which Z3 refuses to redeclare, a tuple silently changes underneath every term
    # built against it. That's what the registry here is preventing.
    describe "declaring" do
      it "is a value object" do
        expect(sort).to eq(TupleSort.new("Point", x: int, y: int))
        expect(sort).to_not eq(TupleSort.new("Pointe", x: int, y: int))
      end

      it "returns the same sort when asked for the same tuple twice" do
        expect(TupleSort.new("Point", x: int, y: int)).to be(sort)
        expect(TupleSort.new(:Point, "x" => int, "y" => int)).to be(sort)
      end

      it "raises when the same name is declared with different fields" do
        sort
        expect{ TupleSort.new("Point", x: int, y: BoolSort.new) }
          .to raise_error(Z3::Exception, "Tuple sort Point is already declared, with fields x: Int, y: Int")
        expect{ TupleSort.new("Point", x: int) }
          .to raise_error(Z3::Exception, "Tuple sort Point is already declared, with fields x: Int, y: Int")
        # Fields are ordered, and swapping two of them is a different tuple
        expect{ TupleSort.new("Point", y: int, x: int) }
          .to raise_error(Z3::Exception, "Tuple sort Point is already declared, with fields x: Int, y: Int")
      end

      it "requires a Hash of fields" do
        expect{ TupleSort.new("BadFields", [int, int]) }
          .to raise_error(Z3::Exception, "Tuple sort needs a Hash of fields, got Array")
      end

      # A tuple with no fields is one nullary constructor, which is exactly what an
      # enum with one value is - there'd be no telling them apart on the way back
      it "requires at least one field" do
        expect{ TupleSort.new("BadEmpty", {}) }
          .to raise_error(Z3::Exception, "Tuple sort needs at least one field")
      end

      it "requires field names to be Symbols" do
        expect{ TupleSort.new("BadName", 1 => int) }
          .to raise_error(Z3::Exception, "Tuple field names must be Symbols, got Integer")
      end

      it "requires field sorts to be Sorts" do
        expect{ TupleSort.new("BadSort", x: 42) }
          .to raise_error(Z3::Exception, "Tuple field x needs a Sort, got Integer")
        expect{ TupleSort.new("BadSort", x: Z3.Int("x")) }
          .to raise_error(Z3::Exception, "Tuple field x needs a Sort, got Int")
      end

      it "requires field names to be distinct" do
        expect{ TupleSort.new("BadDup", {:x => int, "x" => RealSort.new}) }
          .to raise_error(Z3::Exception, "Tuple field names must be distinct, :x repeated")
      end
    end

    # Enums and tuples are both datatypes, and datatype names are one namespace.
    # Z3 refuses the enum-over-tuple direction itself, but declaring a tuple over an
    # enum's name takes the name over and leaves the enum's values unbuildable, so
    # both directions are checked here first.
    describe "sharing the datatype namespace with enums" do
      it "refuses a tuple named after an enum" do
        EnumSort.new("ClashEnumFirst", %i[red green])
        expect{ TupleSort.new("ClashEnumFirst", x: int) }
          .to raise_error(Z3::Exception, "Tuple sort ClashEnumFirst can't be declared, ClashEnumFirst is already an enum sort")
        expect(EnumSort.new("ClashEnumFirst", %i[red green])[:red]).to stringify("red")
      end

      it "refuses an enum named after a tuple" do
        TupleSort.new("ClashTupleFirst", x: int)
        expect{ EnumSort.new("ClashTupleFirst", %i[red green]) }
          .to raise_error(Z3::Exception, "Enum sort ClashTupleFirst can't be declared, ClashTupleFirst is already a tuple sort")
        expect(TupleSort.new("ClashTupleFirst", x: int).mk(1)).to stringify("ClashTupleFirst.mk(1)")
      end
    end

    describe ".from_pointer" do
      let(:solver) do
        Solver.new.tap do |solver|
          solver.from_string <<~SMT2
            (declare-datatypes ((Pair 0)) (((pair (fst Int) (snd Bool)))))
            (declare-const p Pair)
            (assert (= (fst p) 1))
            (assert (snd p))
          SMT2
        end
      end

      it "rebuilds a tuple sort Ruby never declared" do
        expect(solver.check).to eq(:sat)
        var, value = solver.model.each_const.first
        expect(var.sort.inspect).to eq("TupleSort(Pair, fst: Int, snd: Bool)")
        expect(value.value).to eq({fst: 1, snd: true})
      end

      it "lets a rebuilt sort be used from Ruby afterwards" do
        solver.check
        solver.model
        pair = TupleSort.new("Pair", fst: int, snd: BoolSort.new)
        expect(pair.mk(1, true)).to stringify("Pair.mk(1, true)")
      end
    end

    describe "solving" do
      let(:p1) { sort.var("p1") }
      let(:p2) { sort.var("p2") }

      it "solves for fields" do
        expect([p1.x == 3, p1.y == p1.x * 2]).to have_solution(p1 => "Point.mk(3, 6)")
      end

      it "solves for whole tuples" do
        expect([p1 == sort.mk(3, 4), p2 == sort.mk(p1.y, p1.x)])
          .to have_solution(p2 => "Point.mk(4, 3)")
      end

      # Tuples are extensional - two of them with equal fields are equal, and Z3
      # knows it without being told
      it "knows equal fields make equal tuples" do
        solver = Solver.new
        solver.assert p1.x == p2.x
        solver.assert p1.y == p2.y
        solver.assert p1 != p2
        expect(solver.check).to eq(:unsat)
      end

      it "keys arrays" do
        grid = ArraySort.new(sort, int).var("grid")
        expect([grid[[1, 2]] == 42]).to have_solution(grid[sort.mk(1, 2)] => "42")
      end

      it "is a domain and a range for uninterpreted functions" do
        f = Z3.Function("tuple_f", sort, int)
        solver = Solver.new
        solver.assert Z3.ForAll(p1, f[p1] == p1.x + p1.y)
        solver.assert f[sort.mk(2, 3)] != 5
        expect(solver.check).to eq(:unsat)
      end

      it "nests" do
        segment = TupleSort.new("Segment", from: sort, to: sort)
        s = segment.var("s")
        solver = Solver.new
        solver.assert s.from == [1, 2]
        solver.assert s.to.x == 9
        solver.assert s.to.y == 0
        expect(solver.check).to eq(:sat)
        expect(solver.model[s].value).to eq({from: {x: 1, y: 2}, to: {x: 9, y: 0}})
      end
    end
  end
end
