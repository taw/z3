module Z3
  describe DatatypeSort do
    let(:int) { IntSort.new }
    let(:option) { DatatypeSort.new("Option", none: [], some: {value: int}) }
    let(:list) { DatatypeSort.new("List", nil: [], cons: {head: int, tail: :self}) }

    it "to_s" do
      expect(option.to_s).to eq("Option")
    end

    it "inspect" do
      expect(option.inspect).to eq("DatatypeSort(Option, none: {}, some: {value: Int})")
      expect(list.inspect).to eq("DatatypeSort(List, nil: {}, cons: {head: Int, tail: :self})")
    end

    it "constructors" do
      expect(option.constructor_names).to eq(%i[none some])
      expect(option.fields(:some)).to eq({value: int})
      expect(option.fields(:none)).to eq({})
      expect(option.field_names).to eq([:value])
    end

    # `:self` is only unresolved in the declaration - by the time anyone asks, the
    # sort exists and can answer with itself
    it "resolves :self to the sort" do
      expect(list.fields(:cons)).to eq({head: int, tail: list})
      expect(list.var("l").tail.sort).to eq(list)
    end

    it "can instantiate variables" do
      expect(option.var("o").inspect).to eq("Option<o>")
      expect(option.var(%w[o p]).map(&:inspect)).to eq(["Option<o>", "Option<p>"])
    end

    it "accepts an empty Hash as well as an empty Array for a constructor with no fields" do
      expect(DatatypeSort.new("EmptyHash", nothing: {}, just: {just_v: int}).constructor_names).to eq(%i[nothing just])
    end

    describe "#mk" do
      it "builds values" do
        expect(list.mk(:nil)).to stringify("nil")
        expect(list.mk(:cons, 10, list.mk(:nil))).to stringify("cons(10, nil)")
        expect(list.mk(:cons, 10, list.mk(:nil)).sort).to eq(list)
      end

      it "casts arguments to the field sorts" do
        sort = DatatypeSort.new("DtMkCast", none: [], real: {r: RealSort.new}, i: {i: int})
        expect(sort.mk(:real, 1)[:r].sort).to eq(RealSort.new)
      end

      it "takes expressions too" do
        expect(list.mk(:cons, Z3.Int("a"), list.var("l"))).to stringify("cons(a, l)")
      end

      it "raises for an unknown constructor" do
        expect{ list.mk(:snoc, 1) }
          .to raise_error(Z3::Exception, "List has no constructor :snoc, only :nil, :cons")
      end

      it "raises for the wrong number of arguments" do
        expect{ list.mk(:cons, 1) }
          .to raise_error(Z3::Exception, "List constructor :cons takes 2 arguments, got 1")
        expect{ list.mk(:nil, 1) }
          .to raise_error(Z3::Exception, "List constructor :nil takes 0 arguments, got 1")
      end

      it "says which field a bad argument was meant for" do
        expect{ list.mk(:cons, true, list.mk(:nil)) }
          .to raise_error(Z3::Exception, "List field :head: Can't convert true into Int")
      end
    end

    describe "#from_const" do
      it "takes a Symbol for a constructor with no fields" do
        expect(list.from_const(:nil)).to stringify("nil")
        expect(list.from_const("nil")).to stringify("nil")
        expect(list[:nil]).to stringify("nil")
      end

      it "takes a Hash of named fields" do
        expect(list[cons: {head: 10, tail: :nil}]).to stringify("cons(10, nil)")
      end

      it "takes a Hash of fields in order" do
        expect(list[cons: [10, :nil]]).to stringify("cons(10, nil)")
      end

      it "nests" do
        expect(list[cons: {head: 1, tail: {cons: {head: 2, tail: :nil}}}])
          .to stringify("cons(1, cons(2, nil))")
      end

      it "raises for a constructor which takes fields" do
        expect{ list[:cons] }
          .to raise_error(Z3::Exception, /List constructor :cons takes fields/)
      end

      it "raises for more than one constructor" do
        expect{ list[nil: {}, cons: [1, :nil]] }
          .to raise_error(Z3::Exception, "List value needs exactly one constructor, got :nil, :cons")
      end

      it "raises for an unknown field" do
        expect{ list[cons: {head: 1, rest: :nil}] }
          .to raise_error(Z3::Exception, "List constructor :cons has no field :rest")
      end

      it "raises for a missing field" do
        expect{ list[cons: {head: 1}] }
          .to raise_error(Z3::Exception, "List constructor :cons needs a value for field :tail")
      end

      it "raises for anything else" do
        expect{ list.from_const(42) }.to raise_error(Z3::Exception, "Can't convert Integer into List")
        expect{ list.from_const(:snoc) }.to raise_error(Z3::Exception, "Can't convert :snoc into List")
      end
    end

    describe "#accessor and #recognizer" do
      it "finds a field wherever it was declared" do
        expect(list.accessor(:head)[list.var("l")]).to stringify("l.head")
        expect(list.accessor("tail")[list.var("l")]).to stringify("l.tail")
      end

      it "raises for an unknown field" do
        expect{ list.accessor(:rest) }
          .to raise_error(Z3::Exception, "List has no field :rest, only :head, :tail")
      end

      # Z3 calls every recognizer of every datatype `is`, so they can only be told
      # apart by which constructor they came from
      it "finds a recognizer by constructor rather than by name" do
        expect(list.recognizer(:nil)[list.var("l")]).to stringify("l.is_nil")
        expect(list.recognizer(:cons)[list.var("l")]).to stringify("l.is_cons")
        expect(list.recognizer(:nil)).to_not eq(list.recognizer(:cons))
      end
    end

    describe "shapes which are other sorts" do
      # Z3 makes the same sort either way, so Sort.from_pointer couldn't tell them
      # apart afterwards - declaring one has to land on the same class
      it "gives an EnumSort when every constructor takes no fields" do
        sort = DatatypeSort.new("AllNullary", red: [], green: [], blue: [])
        expect(sort).to be_a(EnumSort)
        expect(sort.values).to eq(%i[red green blue])
      end

      it "gives a TupleSort for a single constructor with fields" do
        sort = DatatypeSort.new("OneConstructor", pt: {px: int, py: int})
        expect(sort).to be_a(TupleSort)
        expect(sort.fields).to eq({px: int, py: int})
      end

      # Z3 refuses a datatype with no way to build a finite value, and a lone
      # recursive constructor is exactly that
      it "leaves a single recursive constructor to Z3, which refuses it" do
        expect{ DatatypeSort.new("Stream", scons: {shead: int, stail: :self}) }
          .to raise_error(Z3::Exception, /not well-founded/)
      end
    end

    describe "declaring" do
      it "gives back the same sort for an identical redeclaration" do
        again = DatatypeSort.new("List", nil: [], cons: {head: int, tail: :self})
        expect(again).to be(list)
      end

      # Z3 hands back the sort it already has for the name and attaches a second set
      # of constructors to it, so nothing fails on its side - the registry is the only
      # thing which can notice
      it "raises for a redeclaration with different constructors" do
        expect{ DatatypeSort.new("List", nil: [], cons: {head: BoolSort.new, tail: :self}) }
          .to raise_error(Z3::Exception, /Datatype sort List is already declared/)
      end

      it "raises for a name an enum or a tuple took" do
        EnumSort.new("TakenByEnum", %i[a b])
        TupleSort.new("TakenByTuple", x: int)
        expect{ DatatypeSort.new("TakenByEnum", none: [], some: {tbe: int}) }
          .to raise_error(Z3::Exception, "Datatype sort TakenByEnum can't be declared, TakenByEnum is already an enum sort")
        expect{ DatatypeSort.new("TakenByTuple", none: [], some: {tbt: int}) }
          .to raise_error(Z3::Exception, "Datatype sort TakenByTuple can't be declared, TakenByTuple is already a tuple sort")
      end

      it "keeps enums and tuples off a name it took" do
        DatatypeSort.new("TakenByDatatype", none: [], some: {tbd: int})
        expect{ EnumSort.new("TakenByDatatype", %i[a b]) }
          .to raise_error(Z3::Exception, "Enum sort TakenByDatatype can't be declared, TakenByDatatype is already a datatype sort")
        expect{ TupleSort.new("TakenByDatatype", x: int) }
          .to raise_error(Z3::Exception, "Tuple sort TakenByDatatype can't be declared, TakenByDatatype is already a datatype sort")
      end
    end

    describe "declaration errors" do
      it "needs a Hash of constructors" do
        expect{ DatatypeSort.new("Bad", [:a, :b]) }
          .to raise_error(Z3::Exception, "Datatype sort needs a Hash of constructors, got Array")
        expect{ DatatypeSort.new("Bad", {}) }
          .to raise_error(Z3::Exception, "Datatype sort needs at least one constructor")
      end

      it "needs a Hash of fields" do
        expect{ DatatypeSort.new("Bad", some: 42) }
          .to raise_error(Z3::Exception, "Datatype constructor some needs a Hash of fields, got Integer")
      end

      it "needs Symbols for names" do
        expect{ DatatypeSort.new("Bad", 42 => {}) }
          .to raise_error(Z3::Exception, "Datatype constructor names must be Symbols, got Integer")
        expect{ DatatypeSort.new("Bad", none: [], some: {42 => int}) }
          .to raise_error(Z3::Exception, "Datatype field names must be Symbols, got Integer")
      end

      it "needs a Sort or :self for a field" do
        expect{ DatatypeSort.new("Bad", none: [], some: {v: 42}) }
          .to raise_error(Z3::Exception, "Datatype field v needs a Sort or :self, got Integer")
        expect{ DatatypeSort.new("Bad", none: [], some: {v: :other}) }
          .to raise_error(Z3::Exception, "Datatype field v needs a Sort or :self, got :other")
      end

      # Z3 refuses repeated accessor names itself, and a bare field name has to mean
      # one thing for the field readers and DatatypeExpr#[] to work
      it "needs field names distinct across the whole datatype" do
        expect{ DatatypeSort.new("Bad", a: {f: int}, b: {f: int}) }
          .to raise_error(Z3::Exception, "Datatype field names must be distinct, :f repeated")
      end

      it "needs constructor names distinct" do
        expect{ DatatypeSort.new("Bad", "dup" => {f: int}, :dup => {g: int}) }
          .to raise_error(Z3::Exception, "Datatype constructor names must be distinct, :dup repeated")
      end
    end

    describe ".from_pointer" do
      # A datatype parsed out of SMT-LIB was never declared from Ruby, so everything
      # about it has to be rebuilt from what Z3 knows - the recursive field included,
      # which can't be wrapped as a Sort while the sort it names is still being built
      let(:solver) do
        Solver.new.tap do |solver|
          solver.from_string <<~SMT2
            (declare-datatypes ((Tree 0)) (((leaf) (node (left Tree) (val Int) (right Tree)))))
            (declare-const t Tree)
            (assert (= t (node leaf 3 (node leaf 5 leaf))))
          SMT2
        end
      end

      it "rebuilds a datatype it never declared" do
        solver.check
        sort = solver.model.each_const.first[0].sort
        expect(sort).to be_a(DatatypeSort)
        expect(sort.inspect).to eq("DatatypeSort(Tree, leaf: {}, node: {left: :self, val: Int, right: :self})")
      end

      it "reads values off a rebuilt sort" do
        solver.check
        var, = solver.model.each_const.first
        expect(solver.model[var].value)
          .to eq({node: {left: :leaf, val: 3, right: {node: {left: :leaf, val: 5, right: :leaf}}}})
      end
    end

    describe "solving" do
      it "solves for datatype values" do
        l = list.var("solve_l")
        expect([l.is_cons, l.head == 10, l.tail.is_nil])
          .to have_solution(l => list[cons: {head: 10, tail: :nil}])
      end

      it "knows constructors are distinct" do
        expect([list.var("d").is_nil, list.var("d").is_cons]).to have_no_solution
      end

      # The occurs check, which the datatype theory does for free
      it "knows no value contains itself" do
        l = list.var("occurs")
        expect([l == list.mk(:cons, 1, l)]).to have_no_solution
      end

      it "round-trips a model value back into constraints" do
        l = list.var("round_trip")
        solver = Solver.new
        solver.assert l.is_cons
        solver.assert l.head == 7
        solver.assert l.tail.is_nil
        solver.check
        value = solver.model[l].value
        expect(value).to eq({cons: {head: 7, tail: :nil}})
        expect([l == list[value]]).to have_solution(l => list[value])
      end
    end
  end
end
