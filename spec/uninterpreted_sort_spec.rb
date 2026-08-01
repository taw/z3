module Z3
  describe UninterpretedSort do
    let(:u) { UninterpretedSort.new("U") }
    let(:v) { UninterpretedSort.new("V") }

    it "to_s" do
      expect(u.to_s).to eq("U")
      expect(v.to_s).to eq("V")
    end

    it "inspect" do
      expect(u.inspect).to eq("UninterpretedSort(U)")
      expect(v.inspect).to eq("UninterpretedSort(V)")
    end

    it "is a value object" do
      expect(u).to eq(UninterpretedSort.new("U"))
      expect(u).to_not eq(v)
    end

    it "can instantiate variables" do
      expect(u.var("a").inspect).to eq("U<a>")
    end

    # Z3 symbols are either strings or integers
    it "can be named by an Integer" do
      expect(UninterpretedSort.new(5).inspect).to eq("UninterpretedSort(5)")
      expect(UninterpretedSort.new(5)).to eq(UninterpretedSort.new(5))
      expect(UninterpretedSort.new(5)).to_not eq(UninterpretedSort.new(6))
    end

    it "elements have no interpretation, they can only be equal or distinct" do
      a, b, c = u.var("a"), u.var("b"), u.var("c")
      expect([a != b, b != c, a != c]).to have_solution(a => "U!val!0", b => "U!val!1", c => "U!val!2")
      expect([a != b, b != c, a == c, a != c]).to have_no_solution
    end
  end
end
