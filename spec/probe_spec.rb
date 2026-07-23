module Z3
  describe Probe do
    it "names" do
      expect(Probe.names).to include("num-consts")
    end

    it "descriptions" do
      expect(Probe.description("num-consts")).to eq("number of non Boolean constants in the given goal.")
      expect{Probe.description("no-such-probe")}.to raise_error(Z3::Exception, /\Ano-such-probe not on list of known probes, available: /)
    end

    it "can be created by name" do
      # This used to hand the String straight to probe_inc_ref and corrupt memory
      probe = Probe.new("is-qfbv")
      expect(probe).to be_a(Probe)
      expect(probe.apply(Goal.new)).to eq(1.0)
      expect(Probe.named("is-qfbv")).to be_a(Probe)
    end

    it "accepts pointers from the low level API" do
      expect(Probe.const(10.0)).to be_a(Probe)
      expect(~Probe.new("is-qfbv")).to be_a(Probe)
      expect(Probe.new("size") <= Probe.new("depth")).to be_a(Probe)
    end

    it "rejects unknown probe names and non-probes" do
      expect{Probe.new("no-such-probe")}.to raise_error(Z3::Exception, /\Ano-such-probe not on list of known probes, available: /)
      expect{Probe.named("no-such-probe")}.to raise_error(Z3::Exception, /\Ano-such-probe not on list of known probes, available: /)
      expect{Probe.new(nil)}.to raise_error(Z3::Exception, "Probe name or pointer expected, got NilClass")
      expect{Probe.new(42)}.to raise_error(Z3::Exception, "Probe name or pointer expected, got Integer")
    end

    # Just simple way to brute force coverage
    it "probe building" do
      a = Probe.named("num-consts") < Probe.const(10.0)
      b = Probe.named("size") <= Probe.named("depth")
      c = Probe.named("num-bool-consts") > Probe.const(1.5)
      d = Probe.named("memory") >= Probe.const(4000)
      e = (a == b) & (~c | d)
      expect(e.is_a?(Probe)).to be true
    end
  end
end
