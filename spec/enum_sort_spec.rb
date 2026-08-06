module Z3
  describe EnumSort do
    let(:sort) { EnumSort.new("Color", %i[red green blue]) }

    it "to_s" do
      expect(sort.to_s).to eq("Color")
    end

    it "inspect" do
      expect(sort.inspect).to eq("EnumSort(Color, [:red, :green, :blue])")
    end

    it "values" do
      expect(sort.values).to eq([:red, :green, :blue])
    end

    it "can instantiate variables" do
      expect(sort.var("x").inspect).to eq("Color<x>")
      expect(sort.var(%w[x y]).map(&:inspect)).to eq(["Color<x>", "Color<y>"])
    end

    describe "#[]" do
      it "builds values" do
        expect(sort[:red].inspect).to eq("Color<red>")
        expect(sort[:blue].inspect).to eq("Color<blue>")
      end

      it "takes Strings too" do
        expect(sort["red"].eql?(sort[:red])).to be true
      end

      it "raises for anything which isn't one of the values" do
        expect{ sort[:purple] }.to raise_error(Z3::Exception, "Can't convert :purple into Color")
        expect{ sort[42] }.to raise_error(Z3::Exception, "Can't convert Integer into Color")
        expect{ sort[nil] }.to raise_error(Z3::Exception, "Can't convert nil into Color")
      end
    end

    # Z3 won't declare the same enumeration name twice, so unlike every other sort
    # this one is memoized rather than rebuilt - see EnumSort.new
    describe "declaring" do
      it "is a value object" do
        expect(sort).to eq(EnumSort.new("Color", %i[red green blue]))
        expect(sort).to_not eq(EnumSort.new("Colour", %i[red green blue]))
      end

      it "returns the same sort when asked for the same enum twice" do
        expect(EnumSort.new("Color", %i[red green blue])).to be(sort)
        expect(EnumSort.new(:Color, %w[red green blue])).to be(sort)
      end

      it "raises when the same name is declared with different values" do
        sort
        expect{ EnumSort.new("Color", %i[red green]) }
          .to raise_error(Z3::Exception, "Enum sort Color is already declared, with values [:red, :green, :blue]")
      end

      it "requires a list of Symbols" do
        expect{ EnumSort.new("Bad", :red) }
          .to raise_error(Z3::Exception, "Enum sort needs a list of values")
        expect{ EnumSort.new("Bad", [1, 2]) }
          .to raise_error(Z3::Exception, "Enum values must be Symbols, got Integer")
      end

      # Z3 accepts both, and the results are worse than an error - an enum with no
      # values isn't well-founded, and repeated names make two values which print
      # identically and which #value can't tell apart
      it "requires at least one value, all distinct" do
        expect{ EnumSort.new("Bad", []) }
          .to raise_error(Z3::Exception, "Enum sort needs at least one value")
        expect{ EnumSort.new("Bad", %i[a b a]) }
          .to raise_error(Z3::Exception, "Enum values must be distinct, :a repeated")
      end
    end

    # Nothing is shared between enums - two of them can use the same value name, and
    # the values are still different values of different sorts
    describe "two enums using the same value name" do
      let(:squirrel) { EnumSort.new("Squirrel", %i[red grey black]) }

      it "are different sorts" do
        expect(sort).to_not eq(squirrel)
      end

      it "have different values" do
        expect(sort[:red].eql?(squirrel[:red])).to be false
        expect(sort[:red].inspect).to eq("Color<red>")
        expect(squirrel[:red].inspect).to eq("Squirrel<red>")
      end

      it "can't be mixed" do
        expect{ sort.var("x") == squirrel.var("y") }
          .to raise_error(ArgumentError, "Can't convert Squirrel into Color")
        expect{ sort.var("x") == :grey }
          .to raise_error(Z3::Exception, "Can't convert :grey into Color")
      end
    end

    describe ".from_pointer" do
      # Z3 refuses a second declaration, so a sort which arrived from Z3 - out of a
      # model, or parsed from a file - has to be rebuilt rather than redeclared
      let(:solver) do
        Solver.new.tap do |solver|
          solver.from_string <<~SMT2
            (declare-datatypes ((Suit 0)) (((hearts) (spades) (clubs) (diamonds))))
            (declare-const c Suit)
            (assert (not (= c hearts)))
          SMT2
        end
      end

      it "rebuilds an enum sort Ruby never declared" do
        expect(solver.check).to eq(:sat)
        var, value = solver.model.each_const.first
        expect(var.sort.inspect).to eq("EnumSort(Suit, [:hearts, :spades, :clubs, :diamonds])")
        expect(var.sort).to eq(EnumSort.new("Suit", %i[hearts spades clubs diamonds]))
        expect(%i[spades clubs diamonds]).to include(value.value)
      end

      it "lets a rebuilt sort be declared from Ruby afterwards" do
        solver.check
        solver.model
        suit = EnumSort.new("Suit", %i[hearts spades clubs diamonds])
        expect(suit[:diamonds].inspect).to eq("Suit<diamonds>")
      end

      # One constructor taking arguments is a tuple, and Sort.from_pointer sends it
      # to TupleSort - anything past that is a datatype this gem has no class for
      it "raises for a datatype sort which is neither an enumeration nor a tuple" do
        solver = Solver.new
        solver.from_string <<~SMT2
          (declare-datatypes ((Maybe 0)) (((nothing) (just (val Int)))))
          (declare-const m Maybe)
          (assert (= m (just 1)))
        SMT2
        solver.check
        expect{ solver.model.to_s }
          .to raise_error(Z3::Exception, "Datatype sort Maybe is not an enumeration, its constructor just takes arguments")
      end
    end

    describe "solving" do
      let(:a) { sort.var("a") }
      let(:b) { sort.var("b") }
      let(:c) { sort.var("c") }

      it "solves for enum values" do
        expect([Z3.Distinct(a, b, c), a == :red, b == :blue])
          .to have_solution(a => "red", b => "blue", c => "green")
      end

      # Enum values are exactly the values there are, so the solver counts them
      it "knows the sort has no other values" do
        expect([Z3.Distinct(*sort.var(%w[p q r s]))]).to have_no_solution
        expect([a != :red, a != :green, a != :blue]).to have_no_solution
      end
    end
  end
end
