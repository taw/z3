module Z3
  describe FiniteDomainExpr do
    let(:sort) { FiniteDomainSort.new("FD", 3) }
    let(:x) { sort.var("x") }
    let(:y) { sort.var("y") }
    let(:z) { sort.var("z") }

    describe "#value" do
      # The sort has no literals of its own, so a model is the only place to get one.
      # Three distinct values out of a domain of three pins them to exactly 0, 1 and 2.
      it "gives a Ruby Integer back" do
        solver = Solver.new
        solver.assert Z3.Distinct(x, y, z)
        expect(solver).to be_satisfiable
        model = solver.model
        expect([x, y, z].map { |v| model[v].value }).to all(be_a(Integer))
        expect([x, y, z].map { |v| model[v].value }.sort).to eq([0, 1, 2])
      end

      it "agrees with what the value prints as" do
        solver = Solver.new
        solver.assert Z3.Distinct(x, y, z)
        expect(solver).to be_satisfiable
        model = solver.model
        expect([x, y, z].map { |v| model[v].value.to_s }).to eq([x, y, z].map { |v| model[v].to_s })
      end

      it "raises exception when there's nothing to convert" do
        expect { x.value }.to raise_error(Z3::Exception)
      end
    end
  end
end
