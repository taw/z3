module Z3
  describe BoolExpr do
    let(:a) { Z3.Bool("a") }
    let(:b) { Z3.Bool("b") }
    let(:c) { Z3.Bool("c") }
    let(:x) { Z3.Int("x") }

    it "&" do
      expect([a ==  true, b ==  true, c == (a & b)]).to have_solution(c =>  true)
      expect([a ==  true, b == false, c == (a & b)]).to have_solution(c => false)
      expect([a == false, b ==  true, c == (a & b)]).to have_solution(c => false)
      expect([a == false, b == false, c == (a & b)]).to have_solution(c => false)
    end

    it "|" do
      expect([a ==  true, b ==  true, c == (a | b)]).to have_solution(c =>  true)
      expect([a ==  true, b == false, c == (a | b)]).to have_solution(c =>  true)
      expect([a == false, b ==  true, c == (a | b)]).to have_solution(c =>  true)
      expect([a == false, b == false, c == (a | b)]).to have_solution(c => false)
    end

    it "^" do
      expect([a ==  true, b ==  true, c == (a ^ b)]).to have_solution(c => false)
      expect([a ==  true, b == false, c == (a ^ b)]).to have_solution(c =>  true)
      expect([a == false, b ==  true, c == (a ^ b)]).to have_solution(c =>  true)
      expect([a == false, b == false, c == (a ^ b)]).to have_solution(c => false)
    end

    it "!=" do
      expect([a ==  true, b ==  true, c == (a != b)]).to have_solution(c => false)
      expect([a ==  true, b == false, c == (a != b)]).to have_solution(c =>  true)
      expect([a == false, b ==  true, c == (a != b)]).to have_solution(c =>  true)
      expect([a == false, b == false, c == (a != b)]).to have_solution(c => false)
    end

    it "implies" do
      expect([a ==  true, b ==  true, c == a.implies(b)]).to have_solution(c =>  true)
      expect([a ==  true, b == false, c == a.implies(b)]).to have_solution(c => false)
      expect([a == false, b ==  true, c == a.implies(b)]).to have_solution(c =>  true)
      expect([a == false, b == false, c == a.implies(b)]).to have_solution(c =>  true)
    end

    it "iff" do
      expect([a ==  true, b ==  true, c == a.iff(b)]).to have_solution(c =>  true)
      expect([a ==  true, b == false, c == a.iff(b)]).to have_solution(c => false)
      expect([a == false, b ==  true, c == a.iff(b)]).to have_solution(c => false)
      expect([a == false, b == false, c == a.iff(b)]).to have_solution(c =>  true)
    end

    it "==" do
      expect([a ==  true, b ==  true, c == (a == b)]).to have_solution(c =>  true)
      expect([a ==  true, b == false, c == (a == b)]).to have_solution(c => false)
      expect([a == false, b ==  true, c == (a == b)]).to have_solution(c => false)
      expect([a == false, b == false, c == (a == b)]).to have_solution(c =>  true)
    end

    it "~ and !" do
      expect([a ==  true, b == ~a]).to have_solution(b => false)
      expect([a == false, b == ~a]).to have_solution(b =>  true)
      expect([a ==  true, b == !a]).to have_solution(b => false)
      expect([a == false, b == !a]).to have_solution(b =>  true)
    end

    it "if then else" do
      expect([a ==  true, x == a.ite(2, 3)]).to have_solution(x => 2)
      expect([a == false, x == a.ite(2, 3)]).to have_solution(x => 3)
    end

    it "AtMost" do
      expect([a, b, c, Z3.AtMost([a, b, c], 2)]).to have_no_solution
      expect([a, b, Z3.AtMost([a, b, c], 2)]).to have_solution(c => false)
      expect([a, b, c, Z3.AtMost([a, b, c], 0)]).to have_no_solution
      expect([a, b, c, Z3.AtMost([a, b, c], 3)]).to have_solution(a => true, b => true, c => true)
    end

    it "AtLeast" do
      expect([~a, ~b, ~c, Z3.AtLeast([a, b, c], 1)]).to have_no_solution
      expect([~a, Z3.AtLeast([a, b, c], 2)]).to have_solution(b => true, c => true)
      expect([~a, ~b, ~c, Z3.AtLeast([a, b, c], 0)]).to have_solution(a => false, b => false, c => false)
    end

    it "Exactly" do
      expect([~a, Z3.Exactly([a, b, c], 2)]).to have_solution(b => true, c => true)
      expect([a, b, c, Z3.Exactly([a, b, c], 2)]).to have_no_solution
      expect([~a, ~b, ~c, Z3.Exactly([a, b, c], 1)]).to have_no_solution
      expect([a, b, c, Z3.Exactly([a, b, c], 3)]).to have_solution(a => true, b => true, c => true)
    end

    it "cardinality constraints reject bad bounds" do
      expect{ Z3.AtMost([a, b], -1) }.to raise_error(Z3::Exception)
      expect{ Z3.AtLeast([], 1) }.to raise_error(Z3::Exception)
      expect{ Z3.AtMost([a, b], 1.5) }.to raise_error(Z3::Exception)
      expect{ Z3.Exactly([], 0) }.to raise_error(Z3::Exception)
      expect{ Z3.AtMost([a, b], 2**40) }.to raise_error(Z3::Exception)
    end

    it "AtMost with weights" do
      expect([a, c, Z3.AtMost({a => 3, b => 2, c => 5}, 7)]).to have_no_solution
      expect([a, b, Z3.AtMost({a => 3, b => 2, c => 5}, 7)]).to have_solution(c => false)
      expect([a, b, c, Z3.AtMost({a => 3, b => 2, c => 5}, 10)]).to have_solution(a => true, b => true, c => true)
    end

    it "AtLeast with weights" do
      expect([~c, Z3.AtLeast({a => 3, b => 2, c => 5}, 5)]).to have_solution(a => true, b => true)
      expect([~a, ~b, Z3.AtLeast({a => 3, b => 2, c => 5}, 6)]).to have_no_solution
    end

    it "Exactly with weights" do
      expect([Z3.Exactly({a => 3, b => 2, c => 5}, 5)]).to have_solution(a => true, b => true, c => false)
      expect([~a, ~b, Z3.Exactly({a => 3, b => 2, c => 5}, 4)]).to have_no_solution
    end

    # A count is between 0 and n, so a negative bound on one is a mistake. A weighted
    # total isn't, so the same bound has to be allowed there.
    it "weighted constraints allow negative weights and bounds" do
      expect([b, Z3.AtMost({a => -3, b => 2}, 0)]).to have_solution(a => true)
      expect([~b, Z3.AtMost({a => -3, b => 2}, -1)]).to have_solution(a => true, b => false)
      expect([~a, Z3.AtMost({a => -3, b => 2}, -1)]).to have_no_solution
      expect([~b, Z3.AtLeast({a => 1, b => 0}, 1)]).to have_solution(a => true, b => false)
    end

    # All weights 1 isn't merely equivalent to the list form, it's the same AST
    it "unit weights build the unweighted term" do
      expect(Z3.AtMost({a => 1, b => 1, c => 1}, 2)).to eql(Z3.AtMost([a, b, c], 2))
      expect(Z3.AtLeast({a => 1, b => 1, c => 1}, 2)).to eql(Z3.AtLeast([a, b, c], 2))
      expect(Z3.Exactly({a => 1, b => 1, c => 1}, 2)).to eql(Z3.Exactly([a, b, c], 2))
    end

    # The bound and the weights are decl parameters, not arguments, so a printer which
    # only walks the arguments prints `AtMost([a, b], 1)` and `AtMost([a, b], 2)` the same
    it "cardinality constraints print their bound and weights" do
      expect(Z3.AtMost([a, b, c], 2).to_s).to eq("AtMost([a, b, c], 2)")
      expect(Z3.AtLeast([a, b, c], 2).to_s).to eq("AtLeast([a, b, c], 2)")
      expect(Z3.Exactly([a, b, c], 2).to_s).to eq("Exactly([a, b, c], 2)")
      expect(Z3.AtMost({a => 3, b => 2, c => 5}, 7).to_s).to eq("AtMost({a => 3, b => 2, c => 5}, 7)")
      expect(Z3.AtLeast({a => 3, b => 2, c => 5}, 8).to_s).to eq("AtLeast({a => 3, b => 2, c => 5}, 8)")
      expect(Z3.Exactly({a => 3, b => 2, c => 5}, 7).to_s).to eq("Exactly({a => 3, b => 2, c => 5}, 7)")
      expect(Z3.AtMost({a => -3, b => 2}, -1).to_s).to eq("AtMost({a => -3, b => 2}, -1)")
      expect(Z3.AtMost([a, b], 1).to_s).to_not eq(Z3.AtMost([a, b], 2).to_s)
    end

    it "weighted constraints reject bad weights" do
      expect{ Z3.AtMost({a => 1.5, b => 2}, 3) }.to raise_error(Z3::Exception, /weights must be Integers/)
      expect{ Z3.AtMost({a => "3", b => 2}, 3) }.to raise_error(Z3::Exception, /weights must be Integers/)
      expect{ Z3.AtLeast({a => 2**40}, 3) }.to raise_error(Z3::Exception, /32 bit ints/)
      expect{ Z3.Exactly({a => 1}, 1.5) }.to raise_error(Z3::Exception, /bound must be an Integer/)
      expect{ Z3.AtMost({}, 0) }.to raise_error(Z3::Exception, /at least one argument/)
    end

    # #value is the name every sort uses for "the Ruby object behind this literal",
    # and on Bool it's the same method as #to_b
    it "value" do
      expect{Z3.Bool("a").value}.to raise_error(Z3::Exception, "Can't convert expression a into Boolean")
      expect(Z3.Const(true).value).to eq(true)
      expect(Z3.Const(false).value).to eq(false)
      expect((Z3.Const(true) & Z3.Const(false)).value).to eq(false)
      expect(Z3.Const(true).method(:value).original_name).to eq(:to_b)
    end

    it "to_b" do
      expect{Z3.Bool("a").to_b}.to raise_error(Z3::Exception)
      expect(Z3.Const(true).to_b).to eq(true)
      expect(Z3.Const(false).to_b).to eq(false)
      expect((Z3.Const(true) & Z3.Const(false)).to_b).to eq(false)
    end
  end
end
