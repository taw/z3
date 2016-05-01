module Z3
  describe RealSort do
    it "can instantiate constants" do
      expect(subject.from_const(0).inspect).to eq("Real<0>")
      expect(subject.from_const(42).inspect).to eq("Real<42>")
      expect(subject.from_const(1_000_000_000_000).inspect).to eq("Real<1000000000000>")
      expect(subject.from_const(-1_000_000_000_000).inspect).to eq("Real<-1000000000000>")
      expect(subject.from_const(0.0).inspect).to eq("Real<0>")
      expect(subject.from_const(-0.0).inspect).to eq("Real<0>")
      expect(subject.from_const(3.14).inspect).to eq("Real<157/50>")
      expect(subject.from_const(-3.14).inspect).to eq("Real<-157/50>")
    end

    it "raises exception when trying to convert constants of wrong type" do
      expect{ subject.from_const(true) }.to raise_error(Z3::Exception)
      expect{ subject.from_const(false) }.to raise_error(Z3::Exception)
      expect{ subject.from_const(1.0 / 0.0) }.to raise_error(Z3::Exception)
      expect{ subject.from_const(-1.0 / 0.0) }.to raise_error(Z3::Exception)
      expect{ subject.from_const(0.0 / 0.0) }.to raise_error(Z3::Exception)
    end

    it "can instantiate variables" do
      expect(Z3.Real("a").inspect).to eq("Real<a>")
    end
  end
end
