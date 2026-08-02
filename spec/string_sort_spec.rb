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
        value = sort.from_const(str)
        expect(LowLevel.get_string(value)).to eq(str)
        expect(LowLevel.get_string_length(value)).to eq(str.size)
      end
    end

    # Z3 strings are sequences of code points, so it's characters in the String's
    # own encoding that convert, not bytes
    it "converts characters, not bytes" do
      expect(LowLevel.get_string_length(sort.from_const("é中😀"))).to eq(3)
      expect(LowLevel.get_string_length(sort.from_const("é中😀".b))).to eq(9)
    end

    # Z3 doesn't check this itself, it just quietly stores `\u{30000}` as 9 characters
    it "raises exception for characters outside Z3's alphabet" do
      expect{ sort.from_const("\u{30000}") }.to raise_error(Z3::Exception)
      expect{ sort.from_const("\u{10FFFF}") }.to raise_error(Z3::Exception)
    end

    it "raises exception for strings which aren't valid in their own encoding" do
      expect{ sort.from_const("\xFF") }.to raise_error(Z3::Exception)
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
  end
end
