module Z3
  describe "interface" do
    it "single variables" do
      expect(Z3.Bool("a")).to be_same_as(Z3::BoolSort.new.var("a"))
      expect(Z3.Int("b")).to be_same_as(Z3::IntSort.new.var("b"))
      expect(Z3.Real("c")).to be_same_as(Z3::RealSort.new.var("c"))
      expect(Z3.Bitvec("d", 32)).to be_same_as(Z3::BitvecSort.new(32).var("d"))
      expect(Z3.String("e")).to be_same_as(Z3::StringSort.new.var("e"))
    end

    it "multiple variables" do
      expect(Z3.Int(%W[x y z])).to be_same_as([
        Z3::IntSort.new.var("x"),
        Z3::IntSort.new.var("y"),
        Z3::IntSort.new.var("z"),
      ])
      expect(Z3.String(%W[x y])).to be_same_as([
        Z3::StringSort.new.var("x"),
        Z3::StringSort.new.var("y"),
      ])
    end

    # Z3.String shadows Kernel#String for anything that includes Z3, and Z3 includes
    # itself, so `Const` and friends must not rely on Kernel#String
    it "Z3.String does not break Kernel#String elsewhere" do
      expect(String(42)).to eq("42")
      expect(Z3.Const("abc")).to be_same_as(Z3::StringSort.new.from_const("abc"))
    end
  end
end
