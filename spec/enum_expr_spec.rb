module Z3
  describe EnumExpr do
    let(:sort) { EnumSort.new("Weekday", %i[mon tue wed]) }
    let(:x) { sort.var("x") }

    it "inspect" do
      expect(x.inspect).to eq("Weekday<x>")
      expect(sort[:mon].inspect).to eq("Weekday<mon>")
    end

    it "to_s" do
      expect(sort[:mon].to_s).to eq("mon")
      expect((x == :tue).to_s).to eq("x = tue")
    end

    describe "#==" do
      it "casts Symbols to the enum on the other side" do
        expect((x == :tue).sexpr).to eq("(= x tue)")
        expect((:tue == x).sexpr).to eq("(= x tue)")
        expect((x != :tue).sexpr).to eq("(distinct x tue)")
        expect((:tue != x).sexpr).to eq("(distinct x tue)")
      end

      it "raises for a Symbol which isn't one of the values" do
        expect{ x == :sun }.to raise_error(Z3::Exception, "Can't convert :sun into Weekday")
        expect{ :sun == x }.to raise_error(Z3::Exception, "Can't convert :sun into Weekday")
      end
    end

    describe "#value" do
      it "returns the Symbol behind a value" do
        expect(sort[:mon].value).to eq(:mon)
        expect(sort[:wed].value).to eq(:wed)
      end

      it "simplifies first, like every other #value" do
        expect(Z3.IfThenElse(Z3.Const(true), sort[:tue], sort[:mon]).value).to eq(:tue)
      end

      it "raises for anything which isn't a value" do
        expect{ x.value }.to raise_error(Z3::Exception, "Can't convert expression x into Symbol")
        expect{ Z3.IfThenElse(Z3.Bool("b"), sort[:tue], sort[:mon]).value }
          .to raise_error(Z3::Exception, "Can't convert expression if(b, tue, mon) into Symbol")
      end

      # A variable is an app too, so matching on the decl's name alone would call
      # this variable the value `mon`
      it "is not fooled by a variable named after a value" do
        expect{ sort.var("mon").value }.to raise_error(Z3::Exception, "Can't convert expression mon into Symbol")
      end

      it "comes back from a model" do
        solver = Solver.new
        solver.assert x != :mon
        solver.assert x != :wed
        expect(solver.check).to eq(:sat)
        expect(solver.model[x].value).to eq(:tue)
      end
    end
  end
end
