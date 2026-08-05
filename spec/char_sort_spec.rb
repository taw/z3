module Z3
  describe CharSort do
    let(:sort) { CharSort.new }

    it "to_s" do
      expect(sort.to_s).to eq("Char")
    end

    it "inspect" do
      expect(sort.inspect).to eq("CharSort")
    end

    it "is a value object" do
      expect(sort).to eq(CharSort.new)
      expect(sort).to_not eq(StringSort.new)
    end

    it "can instantiate variables" do
      expect(sort.var("c").inspect).to eq("Char<c>")
    end

    it "can instantiate constants from code points" do
      expect(sort.from_const(97).inspect).to eq(%q{Char<Char("a")>})
      expect(sort.from_const(0).inspect).to eq(%q{Char<Char("\u0000")>})
      expect(sort.from_const(0x4e2d).inspect).to eq(%q{Char<Char("中")>})
      expect(sort.from_const(0x2FFFF).sexpr).to eq("(_ Char 196607)")
    end

    it "can instantiate constants from single character strings" do
      expect(sort.from_const("a").inspect).to eq(sort.from_const(97).inspect)
      expect(sort.from_const("\n").inspect).to eq(sort.from_const(10).inspect)
      expect(sort.from_const("中").inspect).to eq(sort.from_const(0x4e2d).inspect)
    end

    # Z3 doesn't check this itself, it just silently makes a character
    # that no solution can ever contain
    it "raises exception when code point is out of range" do
      expect{ sort.from_const(-1) }.to raise_error(Z3::Exception)
      expect{ sort.from_const(0x30000) }.to raise_error(Z3::Exception)
      expect{ sort.from_const("\u{10FFFF}") }.to raise_error(Z3::Exception)
    end

    it "raises exception when string is not a single character" do
      expect{ sort.from_const("") }.to raise_error(Z3::Exception)
      expect{ sort.from_const("ab") }.to raise_error(Z3::Exception)
    end

    # The other direction of CharExpr#to_bv
    it "#from_bv" do
      expect(sort.from_bv(BitvecSort.new(18).from_const(97))).to be_a(CharExpr)
      expect([sort.var("c") == sort.from_bv(BitvecSort.new(18).from_const(97))])
        .to have_solution(sort.var("c") => sort.from_const("a"))
      expect{ sort.from_bv(BitvecSort.new(8).from_const(97)) }
        .to raise_error(Z3::Exception, "Bitvec(18) expected, got Bitvec(8)")
      expect{ sort.from_bv(97) }
        .to raise_error(Z3::Exception, "Bitvec(18) expected, got Integer")
    end

    it "raises exception when trying to convert constants of wrong type" do
      expect{ sort.from_const(true) }.to raise_error(Z3::Exception)
      expect{ sort.from_const(97.0) }.to raise_error(Z3::Exception)
      expect{ sort.from_const(nil) }.to raise_error(Z3::Exception)
    end
  end
end
