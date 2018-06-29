module Z3
  describe "interface" do
    it "single variables" do
      expect(Z3.Bool("a")).to be_same_as(Z3::BoolSort.new.var("a"))
      expect(Z3.Int("b")).to be_same_as(Z3::IntSort.new.var("b"))
      expect(Z3.Real("c")).to be_same_as(Z3::RealSort.new.var("c"))
      expect(Z3.Bitvec("d", 32)).to be_same_as(Z3::BitvecSort.new(32).var("d"))
    end

    it "multiple variables" do
      expect(Z3.Int(%W[x y z])).to be_same_as([
        Z3::IntSort.new.var("x"),
        Z3::IntSort.new.var("y"),
        Z3::IntSort.new.var("z"),
      ])
    end
  end
end
