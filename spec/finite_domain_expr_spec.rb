module Z3
  describe FiniteDomainExpr do
    let(:sort) { FiniteDomainSort.new("FD", 3) }
    let(:x) { sort.var("x") }
    let(:y) { sort.var("y") }
    let(:z) { sort.var("z") }

    describe "#value" do
      it "gives a Ruby Integer back" do
        expect(sort.from_const(0).value).to eq(0)
        expect(sort.from_const(2).value).to eq(2)
        expect(sort.from_const(2).value).to be_a(Integer)
      end

      it "raises exception when there's nothing to convert" do
        expect { x.value }.to raise_error(Z3::Exception, "Can't convert expression x into Integer")
      end

      # Three distinct values out of a domain of three pins them to exactly 0, 1 and 2
      it "reads a model" do
        solver = Solver.new
        solver.assert Z3.Distinct(x, y, z)
        expect(solver).to be_satisfiable
        model = solver.model
        expect([x, y, z].map { |v| model[v].value }.sort).to eq([0, 1, 2])
      end
    end
  end
end
