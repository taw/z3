module Z3
  describe BitvecExpr do
    let(:a) { Z3.Bitvec("a", 8) }
    let(:b) { Z3.Bitvec("b", 8) }
    let(:c) { Z3.Bitvec("c", 8) }
    let(:d) { Z3.Bitvec("d", 12) }
    let(:x) { Z3.Bool("x") }

    it "==" do
      expect([a == 2, b == -254, x == (a == b)]).to have_solution(x => true)
      expect([a == 2, b == 2, x == (a == b)]).to have_solution(x => true)
      expect([a == 2, b == 3, x == (a == b)]).to have_solution(x => false)
    end

    it "!=" do
      expect([a == 2, b == -254, x == (a != b)]).to have_solution(x => false)
      expect([a == 2, b == 2, x == (a != b)]).to have_solution(x => false)
      expect([a == 2, b == 3, x == (a != b)]).to have_solution(x => true)
    end

    it "+" do
      expect([a == 2, b == 40, c == (a + b)]).to have_solution(c => 42)
      expect([a == 200, b == 40, c == (a + b)]).to have_solution(c => 240)
      expect([a == -1, b == -1, c == (a + b)]).to have_solution(c => 254)
    end

    it "-" do
      expect([a == 50, b == 8, c == (a - b)]).to have_solution(c => 42)
      expect([a == 200, b == 40, c == (a - b)]).to have_solution(c => 160)
      expect([a == 40, b == 200, c == (a - b)]).to have_solution(c => 96)
    end

    it "*" do
      expect([a == 3, b == 40, c == (a * b)]).to have_solution(c => 120)
      expect([a == 30, b == 42, c == (a * b)]).to have_solution(c => 236)
    end

    it "&" do
      expect([a == 50, b == 27, c == (a & b)]).to have_solution(c => 18)
    end

    it "|" do
      expect([a == 50, b == 27, c == (a | b)]).to have_solution(c => 59)
    end

    it "^" do
      expect([a == 50, b == 27, c == (a ^ b)]).to have_solution(c => 41)
    end

    it "xnor" do
      expect([a == 50, b == 27, c == a.xnor(b)]).to have_solution(c => 214)
    end

    it "nand" do
      expect([a == 50, b == 27, c == a.nand(b)]).to have_solution(c => 237)
    end

    it "nor" do
      expect([a == 50, b == 27, c == a.nor(b)]).to have_solution(c => 196)
    end

    it "unary -" do
      expect([a == 50, b == -a]).to have_solution(b => 206)
    end

    it "~" do
      expect([a == 50, b == ~a]).to have_solution(b => 205)
    end

    it ">> (sign-dependent)" do
      expect([a == 234, b == 2, c == a.unsigned_rshift(b)]).to have_solution(c => 58)
      expect([a == 234, b == 2, c == a.signed_rshift(b)]).to have_solution(c => 250)
      expect{ a.rshift(b) }.to raise_error(Z3::Exception)
      expect{ a >> b }.to raise_error(Z3::Exception)
    end

    it "<< (sign-independent)" do
      expect([a == 234, b == 2, c == a.signed_lshift(b)]).to have_solution(c => 168)
      expect([a == 234, b == 2, c == a.unsigned_lshift(b)]).to have_solution(c => 168)
      expect([a == 234, b == 2, c == a.lshift(b)]).to have_solution(c => 168)
      expect([a == 234, b == 2, c == (a << b)]).to have_solution(c => 168)
    end

    it ">" do
      expect{ a > b }.to raise_error(Z3::Exception)
      expect([a == 100, b ==  20, x == a.unsigned_gt(b)]).to have_solution(x => true)
      expect([a == 100, b == 100, x == a.unsigned_gt(b)]).to have_solution(x => false)
      expect([a == 100, b == 120, x == a.unsigned_gt(b)]).to have_solution(x => false)
      expect([a == 100, b == 200, x == a.unsigned_gt(b)]).to have_solution(x => false)
      expect([a == 100, b ==  20, x == a.signed_gt(b)]).to have_solution(x => true)
      expect([a == 100, b == 100, x == a.signed_gt(b)]).to have_solution(x => false)
      expect([a == 100, b == 120, x == a.signed_gt(b)]).to have_solution(x => false)
      expect([a == 100, b == 200, x == a.signed_gt(b)]).to have_solution(x => true)
    end

    it ">=" do
      expect{ a >= b }.to raise_error(Z3::Exception)
      expect([a == 100, b ==  20, x == a.unsigned_ge(b)]).to have_solution(x => true)
      expect([a == 100, b == 100, x == a.unsigned_ge(b)]).to have_solution(x => true)
      expect([a == 100, b == 120, x == a.unsigned_ge(b)]).to have_solution(x => false)
      expect([a == 100, b == 200, x == a.unsigned_ge(b)]).to have_solution(x => false)
      expect([a == 100, b ==  20, x == a.signed_ge(b)]).to have_solution(x => true)
      expect([a == 100, b == 100, x == a.signed_ge(b)]).to have_solution(x => true)
      expect([a == 100, b == 120, x == a.signed_ge(b)]).to have_solution(x => false)
      expect([a == 100, b == 200, x == a.signed_ge(b)]).to have_solution(x => true)
    end

    it "<" do
      expect{ a < b }.to raise_error(Z3::Exception)
      expect([a == 100, b ==  20, x == a.unsigned_lt(b)]).to have_solution(x => false)
      expect([a == 100, b == 100, x == a.unsigned_lt(b)]).to have_solution(x => false)
      expect([a == 100, b == 120, x == a.unsigned_lt(b)]).to have_solution(x =>  true)
      expect([a == 100, b == 200, x == a.unsigned_lt(b)]).to have_solution(x =>  true)
      expect([a == 100, b ==  20, x == a.signed_lt(b)]).to have_solution(x => false)
      expect([a == 100, b == 100, x == a.signed_lt(b)]).to have_solution(x => false)
      expect([a == 100, b == 120, x == a.signed_lt(b)]).to have_solution(x =>  true)
      expect([a == 100, b == 200, x == a.signed_lt(b)]).to have_solution(x => false)
    end

    it "<=" do
      expect{ a <= b }.to raise_error(Z3::Exception)
      expect([a == 100, b ==  20, x == a.unsigned_le(b)]).to have_solution(x => false)
      expect([a == 100, b == 100, x == a.unsigned_le(b)]).to have_solution(x =>  true)
      expect([a == 100, b == 120, x == a.unsigned_le(b)]).to have_solution(x =>  true)
      expect([a == 100, b == 200, x == a.unsigned_le(b)]).to have_solution(x =>  true)
      expect([a == 100, b ==  20, x == a.signed_le(b)]).to have_solution(x => false)
      expect([a == 100, b == 100, x == a.signed_le(b)]).to have_solution(x =>  true)
      expect([a == 100, b == 120, x == a.signed_le(b)]).to have_solution(x =>  true)
      expect([a == 100, b == 200, x == a.signed_le(b)]).to have_solution(x => false)
    end

    it "signed_add_no_overflow?" do
      expect([a ==  100, b ==  100, x == a.signed_add_no_overflow?(b)]).to have_solution(x => false)
      expect([a ==   50, b ==   50, x == a.signed_add_no_overflow?(b)]).to have_solution(x => true)
      expect([a ==  -50, b ==  -50, x == a.signed_add_no_overflow?(b)]).to have_solution(x => true)
      expect([a == -100, b == -100, x == a.signed_add_no_overflow?(b)]).to have_solution(x => true)
    end

    it "unsigned_add_no_overflow?" do
      expect([a ==  100, b ==  100, x == a.unsigned_add_no_overflow?(b)]).to have_solution(x => true)
      expect([a ==   50, b ==   50, x == a.unsigned_add_no_overflow?(b)]).to have_solution(x => true)
      expect([a ==  -50, b ==  -50, x == a.unsigned_add_no_overflow?(b)]).to have_solution(x => false)
      expect([a == -100, b == -100, x == a.unsigned_add_no_overflow?(b)]).to have_solution(x => false)
    end

    # Inherently signed, unsigned add can't underflow
    it "signed_add_no_underflow?" do
      expect([a ==  100, b ==  100, x == a.signed_add_no_underflow?(b)]).to have_solution(x => true)
      expect([a ==   50, b ==   50, x == a.signed_add_no_underflow?(b)]).to have_solution(x => true)
      expect([a ==  -50, b ==  -50, x == a.signed_add_no_underflow?(b)]).to have_solution(x => true)
      expect([a == -100, b == -100, x == a.signed_add_no_underflow?(b)]).to have_solution(x => false)
    end

    # Inherently signed, there is no signed neg
    it "signed_neg_no_overflow?" do
      expect([a ==  100, x == a.signed_neg_no_overflow?]).to have_solution(x => true)
      expect([a == -100, x == a.signed_neg_no_overflow?]).to have_solution(x => true)
      expect([a ==    0, x == a.signed_neg_no_overflow?]).to have_solution(x => true)
      expect([a ==  127, x == a.signed_neg_no_overflow?]).to have_solution(x => true)
      expect([a == -128, x == a.signed_neg_no_overflow?]).to have_solution(x => false)
    end

    # Unsigned div can't overflow, and signed div can only overflow for one value
    it "signed_div_no_overflow?" do
      expect([a ==  -128, b == -1, x == a.signed_div_no_overflow?(b)]).to have_solution(x => false)
      expect([a ==  -128, b == -2, x == a.signed_div_no_overflow?(b)]).to have_solution(x => true)
      expect([a ==   127, b ==  1, x == a.signed_div_no_overflow?(b)]).to have_solution(x => true)
    end

    ## This API is broken, z3 returns unevaluated bvsmul_noovfl(10, 10) instead of actual answer

    # it "signed_mul_no_overflow?" do
    #   expect([a ==   10, b ==   10, x == a.signed_mul_no_overflow?(b)]).to have_solution(x => true)
    #   expect([a ==   20, b ==   10, x == a.signed_mul_no_overflow?(b)]).to have_solution(x => false)
    #   expect([a ==   20, b ==   20, x == a.signed_mul_no_overflow?(b)]).to have_solution(x => false)
    #   expect([a ==  -10, b ==  -10, x == a.signed_mul_no_overflow?(b)]).to have_solution(x => true)
    # end
    #
    # it "unsigned_mul_no_overflow?" do
    #   expect([a ==   10, b ==   10, x == a.unsigned_mul_no_overflow?(b)]).to have_solution(x => true)
    #   expect([a ==   20, b ==   10, x == a.unsigned_mul_no_overflow?(b)]).to have_solution(x => true)
    #   expect([a ==   20, b ==   20, x == a.unsigned_mul_no_overflow?(b)]).to have_solution(x => false)
    #   expect([a ==  -10, b ==  -10, x == a.unsigned_mul_no_overflow?(b)]).to have_solution(x => false)
    # end
    #
    # # Inherently signed, unsigned can't underflow
    # it "signed_mul_no_underflow?" do
    #   expect([a ==  -10, b ==  -10, x == a.signed_mul_no_underflow?(b)]).to have_solution(x => true)
    #   expect([a ==  -20, b ==  -20, x == a.signed_mul_no_underflow?(b)]).to have_solution(x => true)
    #   expect([a ==  -20, b ==   20, x == a.signed_mul_no_underflow?(b)]).to have_solution(x => false)
    # end

    it "zero_ext / sign_ext" do
      expect([a ==  100, d ==  a.zero_ext(4)]).to have_solution(d => 100)
      expect([a == -100, d ==  a.zero_ext(4)]).to have_solution(d => 2**8-100)
      expect([a ==  100, d ==  a.sign_ext(4)]).to have_solution(d => 100)
      expect([a == -100, d ==  a.sign_ext(4)]).to have_solution(d => 2**12-100)
    end

    it "rotate_left / rotate_right" do
      expect([a == 0b0101_0110, b == a.rotate_left(1)]).to have_solution(b => 0b101_0110_0)
      expect([a == 0b0101_0110, b == a.rotate_left(4)]).to have_solution(b => 0b0110_0101)
      expect([a == 0b0101_0110, b == a.rotate_right(1)]).to have_solution(b => 0b0_0101_011)
      expect([a == 0b0101_0110, b == a.rotate_right(4)]).to have_solution(b => 0b0110_0101)
    end
  end
end
