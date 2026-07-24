module Z3
  describe ParamDescrs do
    let(:descrs) { Solver.new.param_descrs }

    it "#size" do
      expect(descrs.size).to eq(descrs.names.size)
      expect(descrs.size).to be > 0
    end

    it "#names" do
      # Which parameters exist depends on Z3 version, so only a few stable ones are checked
      expect(descrs.names).to include("timeout", "rlimit", "random_seed", "unsat_core")
    end

    it "#kind" do
      expect(descrs.kind("timeout")).to eq(:uint)
      expect(descrs.kind("unsat_core")).to eq(:bool)
      expect(descrs.kind("arith.epsilon")).to eq(:double)
      expect(descrs.kind("logic")).to eq(:symbol)
    end

    it "#kind of a parameter that does not exist" do
      expect(descrs.kind("no_such_parameter")).to eq(:invalid)
    end

    it "#kind takes Symbols too" do
      expect(descrs.kind(:timeout)).to eq(:uint)
    end

    it "#include?" do
      expect(descrs).to include("timeout")
      expect(descrs).to_not include("no_such_parameter")
    end

    it "#to_s" do
      expect(descrs.to_s).to include("timeout")
    end

    it "#inspect" do
      expect(descrs.inspect).to eq("Z3::ParamDescrs<#{descrs.size} parameters>")
    end

    it "Optimize accepts a much smaller set of parameters than Solver" do
      optimize_descrs = Optimize.new.param_descrs
      expect(optimize_descrs).to include("timeout", "rlimit")
      expect(optimize_descrs).to_not include("arith.nl")
      expect(optimize_descrs.size).to be < descrs.size
    end
  end
end
