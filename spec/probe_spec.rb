module Z3
  describe Probe do
    it "names" do
      expect(Probe.names).to include("num-consts")
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
