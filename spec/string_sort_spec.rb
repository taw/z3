module Z3
  describe StringSort do
    let(:sort) { StringSort.new }

    it "to_s" do
      expect(sort.to_s).to eq("String")
    end

    it "inspect" do
      expect(sort.inspect).to eq("StringSort")
    end

    it "is a value object" do
      expect(sort).to eq(StringSort.new)
      expect(sort).to_not eq(SeqSort.new(IntSort.new))
    end

    it "element_sort" do
      expect(sort.element_sort).to eq(CharSort.new)
    end

    it "can instantiate variables" do
      expect(sort.var("s").inspect).to eq("String<s>")
    end

    it "can instantiate constants" do
      expect(sort.from_const("hello").inspect).to eq(%q{String<"hello">})
      expect(sort.from_const("").inspect).to eq(%q{String<"">})
      expect(sort.from_const("中").inspect).to eq(%q{String<"中">})
    end

    # Z3 takes strings in a half-escaped form, so every one of these goes
    # through a different path in and out
    it "can instantiate constants of anything Z3 has to escape" do
      [
        "hello",
        "",
        %q{a"b},
        "tab\there",
        "nul\0end",
        "back\\slash",
        "not \\u{41} an escape",
        "é中😀",
        "\u{2FFFF}",
      ].each do |str|
        expect(sort.from_const(str)).to stringify(str.inspect)
      end
    end

    # Z3 strings are sequences of code points, so it's characters in the String's
    # own encoding that convert, not bytes
    it "converts characters, not bytes" do
      expect(sort.from_const("é")).to stringify(%q{"é"})
      expect(sort.from_const("é".b)).to stringify(%q{"Ã©"})
    end

    # Z3 doesn't check this itself, it just quietly stores `\u{30000}` as 9 characters
    it "raises exception for characters outside Z3's alphabet" do
      expect{ sort.from_const("\u{30000}") }.to raise_error(Z3::Exception)
      expect{ sort.from_const("\u{10FFFF}") }.to raise_error(Z3::Exception)
    end

    it "raises exception for strings which aren't valid in their own encoding" do
      expect{ sort.from_const("\xFF") }.to raise_error(Z3::Exception)
    end

    it "Z3.Const builds string constants" do
      expect(Z3.Const("hello")).to be_same_as(sort.from_const("hello"))
    end

    it "raises exception when trying to convert constants of wrong type" do
      expect{ sort.from_const(42) }.to raise_error(Z3::Exception)
      expect{ sort.from_const(nil) }.to raise_error(Z3::Exception)
      expect{ sort.from_const(["a", "b"]) }.to raise_error(Z3::Exception)
    end

    it "values can be used in constraints" do
      s = sort.var("s")
      expect([s == sort.from_const("héllo")]).to have_solution(s => %q{"héllo"})
    end

    # Expr.sort_for_const knows about String, so no explicit from_const is needed
    it "Ruby Strings autoconvert in constraints" do
      s = sort.var("s")
      expect([s == "héllo"]).to have_solution(s => %q{"héllo"})
      expect([s != "a", s != "b", s.sort.from_const("") != s, "c" == s]).to have_solution(s => %q{"c"})
      expect([s == "a", s == "b"]).to have_no_solution
    end

    # These live on the sort rather than as IntExpr#to_str and friends: `to_str` is
    # Ruby's implicit String conversion, and `to_s` is every AST's printed form
    describe "building from other sorts" do
      let(:s) { sort.var("s") }

      it "#from_int" do
        expect([s == sort.from_int(42)]).to have_solution(s => %q{"42"})
        expect([s == sort.from_int(0)]).to have_solution(s => %q{"0"})
        # SMT-LIB gives a negative number no string form at all, rather than "-1"
        expect([s == sort.from_int(-1)]).to have_solution(s => %q{""})
        expect([s == sort.from_int(Z3.Int("i")), Z3.Int("i") == 7]).to have_solution(s => %q{"7"})
      end

      # StringExpr#to_code backwards
      it "#from_code" do
        expect([s == sort.from_code(65)]).to have_solution(s => %q{"A"})
        expect([s == sort.from_code(0x4e2d)]).to have_solution(s => %q{"中"})
      end

      # The same eight bits read either way
      it "#from_unsigned_bv / #from_signed_bv" do
        bits = BitvecSort.new(8).from_const(-3)
        expect([s == sort.from_unsigned_bv(bits)]).to have_solution(s => %q{"253"})
        expect([s == sort.from_signed_bv(bits)]).to have_solution(s => %q{"-3"})
        expect{ sort.from_signed_bv(42) }.to raise_error(Z3::Exception, "Bitvec expected, got Integer")
        expect{ sort.from_unsigned_bv(nil) }.to raise_error(Z3::Exception, "Bitvec expected, got nil")
      end
    end
  end
end
