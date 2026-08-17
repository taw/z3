module Z3
  describe Sort do
    let(:bool_sort) { BoolSort.new }
    let(:int_sort)  { IntSort.new }
    let(:real_sort) { RealSort.new }
    let(:bv8_sort)  { BitvecSort.new(8) }
    let(:bv32_sort) { BitvecSort.new(32) }

    let(:sorts) { [bool_sort, int_sort, real_sort, bv8_sort, bv32_sort] }

    # Every sort the gem wraps, each of them the only one of its class here
    let(:all_sorts) {
      sorts + [
        SetSort.new(IntSort.new),
        ArraySort.new(IntSort.new, IntSort.new),
        FloatSort.new(:single),
        RoundingModeSort.new,
        UninterpretedSort.new("U"),
        FiniteDomainSort.new("FD", 3),
        CharSort.new,
        StringSort.new,
        SeqSort.new(IntSort.new),
        ReSort.new(StringSort.new),
        TypeVariableSort.new("T"),
      ]
    }

    it "can't instantiate Sort abstract superclass" do
      expect{ Sort.new }.to raise_error(NoMethodError)
    end

    # Seq, Re, Char, uninterpreted, finite domain and type variable sorts used to fall
    # back to plain Exprs, which meant no place to hang their operations
    it "every sort has an Expr class of its own" do
      expect(all_sorts.map(&:expr_class).uniq).to eq([
        BoolExpr, IntExpr, RealExpr, BitvecExpr, SetExpr, ArrayExpr, FloatExpr,
        RoundingModeExpr, UninterpretedExpr, FiniteDomainExpr, CharExpr,
        StringExpr, SeqExpr, ReExpr, TypeVariableExpr,
      ])
    end

    it "#var and #new build Exprs of that class" do
      all_sorts.each do |sort|
        expect(sort.var("v")).to be_a(sort.expr_class)
      end
    end

    # Z3 appends a number from a counter shared by the whole context - and shared
    # with FuncDecl.declare_fresh - so nothing here may assert which one it gets
    describe "#fresh_var" do
      it "works on every sort" do
        all_sorts.each do |sort|
          fresh = sort.fresh_var("v")
          expect(fresh).to be_a(sort.expr_class)
          expect(fresh.sort).to eq(sort)
          expect(fresh.to_s).to start_with("v")
        end
      end

      it "picks a different name every time" do
        names = 3.times.map { IntSort.new.fresh_var("v").to_s }
        expect(names.uniq.size).to eq(3)
      end

      it "takes a Symbol prefix too" do
        expect(IntSort.new.fresh_var(:tmp).to_s).to start_with("tmp")
      end

      # Which is the point - two of them are unrelated variables, where #var with
      # one name twice is the same variable twice
      it "is a different variable each time, not just a different name" do
        a = IntSort.new.fresh_var("v")
        b = IntSort.new.fresh_var("v")
        expect([a == 1, b == 2]).to have_solution({})
        expect([IntSort.new.var("same") == 1, IntSort.new.var("same") == 2]).to have_no_solution
      end
    end

    # Nothing returns one any more, so it's abstract like ArithExpr
    it "Expr itself is abstract" do
      expect{ Expr.new(nil, nil) }.to raise_error(NoMethodError)
      expect(all_sorts.map(&:expr_class)).to_not include(Expr)
    end

    # Datatype and relation sorts are still unwrapped, but there's no way to build one yet
    it ".from_pointer round-trips every sort the gem wraps" do
      all_sorts.each do |sort|
        expect(Sort.from_pointer(sort._ast)).to be_same_as(sort)
      end
    end

    # Z3 represents String as Seq(Char), and SeqSort.new hands that back as a StringSort,
    # so there's no sort left whose class .from_pointer would have to guess at
    it ".from_pointer returns Seq(Char) as StringSort" do
      expect(Sort.from_pointer(SeqSort.new(CharSort.new)._ast)).to be_same_as(StringSort.new)
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
        all = all_sorts + [array_of_bool, SeqSort.new(CharSort.new)]
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

    # Every sort but one is recognised by its `Z3_sort_kind`, which every Z3 has - so a
    # sort from a newer Z3 falls through to "Unknown sort kind" and bothers nobody else.
    # A finite set has no kind of its own, so it has to be recognised by asking
    # `Z3_is_finite_set_sort`, a function Z3 4.x hasn't got - and #from_pointer runs on
    # the path of every model read, so calling it there unconditionally took the whole
    # gem down on 4.x rather than just finite sets.
    describe "on a Z3 without finite sets" do
      before do
        allow(Sort).to receive(:finite_sets?).and_return(false)
      end

      it "doesn't ask a question that Z3 has no function to answer" do
        expect(VeryLowLevel).to_not receive(:Z3_is_finite_set_sort)
        all_sorts.each do |sort|
          expect(Sort.from_pointer(sort._ast)).to eq(sort)
        end
      end

      it "says what's wrong when someone actually asks for one" do
        expect { FiniteSetSort.new(IntSort.new) }
          .to raise_error(Z3::Exception, /Finite sets need Z3 5\.0 or newer/)
      end
    end
  end
end
