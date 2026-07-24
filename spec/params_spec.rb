module Z3
  describe Params do
    let(:descrs) { Solver.new.param_descrs }

    it "starts out empty" do
      expect(Params.new.to_s).to eq("(params)")
    end

    it "sets uint parameters" do
      expect(Params.new(timeout: 10).to_s).to eq("(params timeout 10)")
    end

    it "sets bool parameters" do
      expect(Params.new(unsat_core: true).to_s).to eq("(params unsat_core true)")
      expect(Params.new(unsat_core: false).to_s).to eq("(params unsat_core false)")
    end

    it "sets double parameters" do
      expect(Params.new("arith.epsilon" => 0.25).to_s).to eq("(params arith.epsilon 0.25)")
    end

    it "sets symbol parameters, from either a String or a Symbol" do
      expect(Params.new(logic: "QF_LIA").to_s).to eq("(params logic QF_LIA)")
      expect(Params.new(logic: :QF_LIA).to_s).to eq("(params logic QF_LIA)")
    end

    it "takes parameter names as either Strings or Symbols" do
      expect(Params.new("timeout" => 10).to_s).to eq("(params timeout 10)")
      expect(Params.new(timeout: 10).to_s).to eq("(params timeout 10)")
    end

    it "#[]=" do
      params = Params.new(timeout: 10)
      params[:random_seed] = 42
      expect(params.to_s).to eq("(params timeout 10 random_seed 42)")
    end

    it "#[]= overrides values set before" do
      params = Params.new(timeout: 10)
      params[:timeout] = 20
      expect(params.to_s).to eq("(params timeout 20)")
    end

    it "rejects values no Z3 parameter could hold" do
      expect{ Params.new(timeout: nil) }.to raise_error(Z3::Exception, "Can't use nil as value of parameter `timeout'")
      expect{ Params.new(timeout: [1]) }.to raise_error(Z3::Exception, "Can't use [1] as value of parameter `timeout'")
    end

    it "rejects Integers that do not fit a uint parameter" do
      expect{ Params.new(timeout: -1) }.to raise_error(Z3::Exception, "Parameter `timeout' expects uint, got -1")
      expect{ Params.new(timeout: 2**32) }.to raise_error(Z3::Exception, "Parameter `timeout' expects uint, got 4294967296")
    end

    describe "with parameter descriptions" do
      it "checks parameter names" do
        expect{ Params.new({timout: 1000}, descrs) }
          .to raise_error(Z3::Exception, "Unknown parameter `timout'")
      end

      it "checks parameter types" do
        expect{ Params.new({timeout: true}, descrs) }
          .to raise_error(Z3::Exception, "Parameter `timeout' expects uint, got true")
        expect{ Params.new({unsat_core: 1}, descrs) }
          .to raise_error(Z3::Exception, "Parameter `unsat_core' expects bool, got 1")
        expect{ Params.new({logic: 1}, descrs) }
          .to raise_error(Z3::Exception, "Parameter `logic' expects symbol, got 1")
      end

      it "goes by the declared type, so Integers are fine for double parameters" do
        expect(Params.new({"arith.epsilon" => 1}, descrs).to_s).to eq("(params arith.epsilon 1)")
      end

      it "reports parameters the Ruby API has no setter for" do
        expect{ Params.new({"qi.cost" => "(+ weight generation)"}, descrs) }
          .to raise_error(Z3::Exception, "Parameter `qi.cost' has type string, which this API can't set")
      end

      it "#descrs" do
        params = Params.new({timeout: 10}, descrs)
        expect(params.descrs).to equal(descrs)
        expect(Params.new(timeout: 10).descrs).to be_nil
      end
    end
  end
end
