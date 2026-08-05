module Z3
  describe BitvecExpr do
    let(:a) { Z3.Bitvec("a", 8) }
    let(:b) { Z3.Bitvec("b", 8) }
    let(:c) { Z3.Bitvec("c", 8) }
    let(:d) { Z3.Bitvec("d", 12) }
    let(:e) { Z3.Bitvec("e", 4) }
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

    it "/" do
      expect{ a / b }.to raise_error(Z3::Exception)
      expect([a == 200, b == 20, c == a.unsigned_div(b)]).to have_solution(c => 10)
      expect([a == 200, b == 20, c == a.signed_div(b)]).to have_solution(c => 254)
    end

    it "%" do
      expect{ a % b }.to raise_error(Z3::Exception)
      expect([a == 200, b == 20, c == a.signed_mod(b)]).to have_solution(c => 4)
      expect([a == 200, b == 20, c == a.signed_rem(b)]).to have_solution(c => 240)
      expect([a == 200, b == 20, c == a.unsigned_rem(b)]).to have_solution(c => 0)
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

    it "~ and !" do
      expect([a == 50, b == ~a]).to have_solution(b => 205)
      expect([a == 50, b == !a]).to have_solution(b => 205)
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

    # Signedness matters, so the unqualified version just tells you to pick one
    it "add_no_overflow?" do
      expect{ a.add_no_overflow?(b) }.to raise_error(Z3::Exception, /signed_add_no_overflow/)
    end

    # Inherently signed, unsigned add can't underflow
    it "signed_add_no_underflow?" do
      expect([a ==  100, b ==  100, x == a.signed_add_no_underflow?(b)]).to have_solution(x => true)
      expect([a ==   50, b ==   50, x == a.signed_add_no_underflow?(b)]).to have_solution(x => true)
      expect([a ==  -50, b ==  -50, x == a.signed_add_no_underflow?(b)]).to have_solution(x => true)
      expect([a == -100, b == -100, x == a.signed_add_no_underflow?(b)]).to have_solution(x => false)
      expect{ a.unsigned_add_no_underflow?(b) }.to raise_error(Z3::Exception)
    end

    # Inherently signed, there is no signed neg
    it "signed_neg_no_overflow?" do
      expect([a ==  100, x == a.signed_neg_no_overflow?]).to have_solution(x => true)
      expect([a == -100, x == a.signed_neg_no_overflow?]).to have_solution(x => true)
      expect([a ==    0, x == a.signed_neg_no_overflow?]).to have_solution(x => true)
      expect([a ==  127, x == a.signed_neg_no_overflow?]).to have_solution(x => true)
      expect([a == -128, x == a.signed_neg_no_overflow?]).to have_solution(x => false)
      expect{ a.unsigned_neg_no_overflow? }.to raise_error(Z3::Exception)
    end

    # Unsigned div can't overflow, and signed div can only overflow for one value
    it "signed_div_no_overflow?" do
      expect([a ==  -128, b == -1, x == a.signed_div_no_overflow?(b)]).to have_solution(x => false)
      expect([a ==  -128, b == -2, x == a.signed_div_no_overflow?(b)]).to have_solution(x => true)
      expect([a ==   127, b ==  1, x == a.signed_div_no_overflow?(b)]).to have_solution(x => true)
      expect{ a.unsigned_div_no_overflow?(b) }.to raise_error(Z3::Exception)
    end

    # This changes based on Z3 version, so I'm not sure what's supposed semantics here
    # This documents what Z3 4.16 does, so skip on older versions
    it "signed_mul_no_overflow?" do
      skip "Semantics differ on Z3 older than 4.16" unless Z3.version_at_least?(4, 16)

      expect([a ==   10, b ==   10, x == a.signed_mul_no_overflow?(b)]).to have_solution(x => true)
      expect([a ==   20, b ==   10, x == a.signed_mul_no_overflow?(b)]).to have_solution(x => false)
      expect([a ==   20, b ==   20, x == a.signed_mul_no_overflow?(b)]).to have_solution(x => false)
      expect([a ==   10, b ==  -10, x == a.signed_mul_no_overflow?(b)]).to have_solution(x => true)
      expect([a ==  -10, b ==   10, x == a.signed_mul_no_overflow?(b)]).to have_solution(x => true)
      expect([a ==  -10, b ==  -10, x == a.signed_mul_no_overflow?(b)]).to have_solution(x => true)
      expect([a ==  100, b ==  100, x == a.signed_mul_no_overflow?(b)]).to have_solution(x => false)
      expect([a == -100, b ==  100, x == a.signed_mul_no_overflow?(b)]).to have_solution(x => true)
      expect([a == -100, b == -100, x == a.signed_mul_no_overflow?(b)]).to have_solution(x => false)
    end

    it "unsigned_mul_no_overflow?" do
      expect([a ==   10, b ==   10, x == a.unsigned_mul_no_overflow?(b)]).to have_solution(x => true)
      expect([a ==   20, b ==   10, x == a.unsigned_mul_no_overflow?(b)]).to have_solution(x => true)
      expect([a ==   20, b ==   20, x == a.unsigned_mul_no_overflow?(b)]).to have_solution(x => false)
      expect([a ==  -10, b ==  -10, x == a.unsigned_mul_no_overflow?(b)]).to have_solution(x => false)
    end

    # # Inherently signed, unsigned can't underflow
    it "signed_mul_no_underflow?" do
      expect([a ==  -10, b ==  -10, x == a.signed_mul_no_underflow?(b)]).to have_solution(x => true)
      expect([a ==  -20, b ==  -20, x == a.signed_mul_no_underflow?(b)]).to have_solution(x => true)
      expect([a ==  -20, b ==   20, x == a.signed_mul_no_underflow?(b)]).to have_solution(x => false)
      expect{ a.unsigned_mul_no_underflow?(b) }.to raise_error(Z3::Exception)
    end

    # Signedness matters, so the unqualified version just tells you to pick one
    it "mul_no_overflow?" do
      expect{ a.mul_no_overflow?(b) }.to raise_error(Z3::Exception, /signed_mul_no_overflow/)
    end

    # Subtraction is the mirror image of addition - only signed can overflow here,
    # so this is the one which doesn't need a sign picking
    it "signed_sub_no_overflow?" do
      expect([a ==   50, b ==   50, x == a.sub_no_overflow?(b)]).to have_solution(x => true)
      expect([a ==  100, b == -100, x == a.sub_no_overflow?(b)]).to have_solution(x => false)
      expect([a ==  127, b ==   -1, x == a.sub_no_overflow?(b)]).to have_solution(x => false)
      expect([a == -128, b ==    1, x == a.sub_no_overflow?(b)]).to have_solution(x => true)
      expect([a ==   50, b ==   50, x == a.signed_sub_no_overflow?(b)]).to have_solution(x => true)
      expect([a ==  127, b ==   -1, x == a.signed_sub_no_overflow?(b)]).to have_solution(x => false)
      expect{ a.unsigned_sub_no_overflow?(b) }.to raise_error(Z3::Exception, "Unsigned - can't overflow")
    end

    # ...and both signs can underflow here, so this is the one which does
    it "signed_sub_no_underflow? / unsigned_sub_no_underflow?" do
      expect([a ==  100, b ==   50, x == a.signed_sub_no_underflow?(b)]).to have_solution(x => true)
      expect([a == -100, b ==  100, x == a.signed_sub_no_underflow?(b)]).to have_solution(x => false)
      expect([a == -128, b ==    1, x == a.signed_sub_no_underflow?(b)]).to have_solution(x => false)
      expect([a ==  100, b ==   50, x == a.unsigned_sub_no_underflow?(b)]).to have_solution(x => true)
      expect([a ==   50, b ==  100, x == a.unsigned_sub_no_underflow?(b)]).to have_solution(x => false)
      expect{ a.sub_no_underflow?(b) }.to raise_error(Z3::Exception, /signed_sub_no_underflow/)
    end

    it "zero_ext / sign_ext" do
      expect([a ==  100, d ==  a.zero_ext(4)]).to have_solution(d => 100)
      expect([a == -100, d ==  a.zero_ext(4)]).to have_solution(d => 2**8-100)
      expect([a ==  100, d ==  a.sign_ext(4)]).to have_solution(d => 100)
      expect([a == -100, d ==  a.sign_ext(4)]).to have_solution(d => 2**12-100)
      expect{ a.zero_ext(-1) }.to raise_error(Z3::Exception)
      expect{ a.sign_ext(-1) }.to raise_error(Z3::Exception)
      expect{ a.zero_ext(1.5) }.to raise_error(Z3::Exception)
      expect{ a.sign_ext(1.5) }.to raise_error(Z3::Exception)
    end

    it "rotate_left / rotate_right" do
      expect([a == 0b0101_0110, b == a.rotate_left(1)]).to have_solution(b => 0b101_0110_0)
      expect([a == 0b0101_0110, b == a.rotate_left(4)]).to have_solution(b => 0b0110_0101)
      expect([a == 0b0101_0110, b == a.rotate_right(1)]).to have_solution(b => 0b0_0101_011)
      expect([a == 0b0101_0110, b == a.rotate_right(4)]).to have_solution(b => 0b0110_0101)
      expect{ a.rotate_left(-1) }.to raise_error(Z3::Exception)
      expect{ a.rotate_right(-1) }.to raise_error(Z3::Exception)
      expect{ a.rotate_left(1.5) }.to raise_error(Z3::Exception)
      expect{ a.rotate_right(1.5) }.to raise_error(Z3::Exception)
    end

    # Z3 has a second rotate for amounts it can't know in advance. An Integer still
    # goes to the fixed one, as that gives the solver more to work with.
    it "rotate_left / rotate_right by a Bitvec" do
      expect([a == 0b0101_0110, c == 1, b == a.rotate_left(c)]).to have_solution(b => 0b101_0110_0)
      expect([a == 0b0101_0110, c == 4, b == a.rotate_left(c)]).to have_solution(b => 0b0110_0101)
      expect([a == 0b0101_0110, c == 1, b == a.rotate_right(c)]).to have_solution(b => 0b0_0101_011)
      expect([a == 0b0101_0110, c == 4, b == a.rotate_right(c)]).to have_solution(b => 0b0110_0101)
      # A rotation Z3 has to solve for, which the fixed version can't express at all
      expect([a == 0b0000_0001, b == 0b0001_0000, a.rotate_left(c) == b, c.unsigned_lt(8)]).to have_solution(c => 4)
      expect{ a.rotate_left(d) }.to raise_error(Z3::Exception, "Can't convert Bitvec(12) into Bitvec(8)")
    end

    it "bit" do
      # Bit 0 is the low one, so this reads backwards from how the literal is written
      [true, false, true, false, false, true, false, true].each_with_index do |set, i|
        expect([a == 0b1010_0101, x == a.bit(i)]).to have_solution(x => set)
      end
      expect{ a.bit(8) }.to raise_error(Z3::Exception, "Trying to take a bit out of range")
      expect{ a.bit(-1) }.to raise_error(Z3::Exception, "Trying to take a bit out of range")
      expect{ a.bit(1.5) }.to raise_error(Z3::Exception, "Trying to take a bit out of range")
    end

    it "repeat" do
      expect([e == 0b1101, a == e.repeat(2)]).to have_solution(a => 0b1101_1101)
      expect([e == 0b0011, d == e.repeat(3)]).to have_solution(d => 0b0011_0011_0011)
      expect(e.repeat(3).sort).to eq(BitvecSort.new(12))
      expect{ a.repeat(0) }.to raise_error(Z3::Exception, "Repeat count must be a positive Integer")
      expect{ a.repeat(1.5) }.to raise_error(Z3::Exception, "Repeat count must be a positive Integer")
    end

    # Z3 answers with a one-bit Bitvec, which is why there are Bool versions too
    it "redand / redor" do
      expect(a.redand.sort).to eq(BitvecSort.new(1))
      expect(a.redor.sort).to eq(BitvecSort.new(1))
      expect([a == 0b1111_1111, x == a.all_bits_set?]).to have_solution(x => true)
      expect([a == 0b1111_1110, x == a.all_bits_set?]).to have_solution(x => false)
      expect([a == 0b0000_0000, x == a.any_bits_set?]).to have_solution(x => false)
      expect([a == 0b0000_0001, x == a.any_bits_set?]).to have_solution(x => true)
    end

    # #value leaves Z3 for a Ruby Integer, where #to_i builds a Z3 Int expression -
    # the two families are named alike but they are not the same thing
    it "signed_value / unsigned_value" do
      bv = BitvecSort.new(8)
      expect(bv.from_const(200).unsigned_value).to eq(200)
      expect(bv.from_const(200).signed_value).to eq(-56)
      expect(bv.from_const(7).signed_value).to eq(7)
      expect(bv.from_const(-1).unsigned_value).to eq(255)
      # The boundary the sign flips at
      expect(bv.from_const(127).signed_value).to eq(127)
      expect(bv.from_const(128).signed_value).to eq(-128)
      # One bit wide, where the only two values are 0 and -1 signed
      expect(BitvecSort.new(1).from_const(1).signed_value).to eq(-1)
      expect(BitvecSort.new(1).from_const(1).unsigned_value).to eq(1)
      # Simplified first, so it doesn't have to be written as a literal
      expect((bv.from_const(200) + 1).unsigned_value).to eq(201)
      expect{ a.unsigned_value }.to raise_error(Z3::Exception, "Can't convert expression a into Integer")
      expect{ a.value }.to raise_error(Z3::Exception, /signed_value/)
    end

    it "signed_to_i / unsigned_to_i" do
      int = Z3.Int("i")
      expect([a == 200, int == a.unsigned_to_i]).to have_solution(int => 200)
      expect([a == 200, int == a.signed_to_i]).to have_solution(int => -56)
      expect([a ==   7, int == a.signed_to_i]).to have_solution(int => 7)
      expect(a.unsigned_to_i.sort).to eq(IntSort.new)
      expect{ a.to_i }.to raise_error(Z3::Exception, /signed_to_i/)
    end

    # The other direction lives on IntExpr, and truncates rather than failing
    it "IntExpr#to_bv" do
      int = Z3.Int("i")
      expect([int ==  42, a == int.to_bv(8)]).to have_solution(a => 42)
      expect([int == 300, a == int.to_bv(8)]).to have_solution(a => 44)
      expect([int ==  -1, a == int.to_bv(8)]).to have_solution(a => 255)
      expect(int.to_bv(8).sort).to eq(BitvecSort.new(8))
      expect{ int.to_bv(0) }.to raise_error(Z3::Exception, "Bitvec width must be a positive Integer")
    end

    it "extract" do
      expect([a == 0b0101_0110, e == a.extract(3, 0)]).to have_solution(e => 0b0110)
      expect([a == 0b0101_0110, e == a.extract(7, 4)]).to have_solution(e => 0b0101)
      expect{ a.extract(8, 4) }.to raise_error(Z3::Exception)
      expect{ a.extract(2, 3) }.to raise_error(Z3::Exception)
      expect{ a.extract(2, -1) }.to raise_error(Z3::Exception)
    end

    it "concat" do
      expect([a == 0b0101_0110, e == 0b1101, d == a.concat(e)]).to have_solution(d => 0b0101_0110_1101)
      expect([a == 0b0101_0110, e == 0b1101, d == e.concat(a)]).to have_solution(d => 0b1101_0101_0110)
    end

    it "zero?" do
      expect([a == 0, x == a.zero?]).to have_solution(x => true)
      expect([a == 100, x == a.zero?]).to have_solution(x => false)
      expect([a == 200, x == a.zero?]).to have_solution(x => false)
    end

    it "nonzero?" do
      expect([a == 0, x == a.nonzero?]).to have_solution(x => false)
      expect([a == 100, x == a.nonzero?]).to have_solution(x => true)
      expect([a == 200, x == a.nonzero?]).to have_solution(x => true)
    end

    # Inherently signed
    it "positive?" do
      expect([a == 0, x == a.positive?]).to have_solution(x => false)
      expect([a == 100, x == a.positive?]).to have_solution(x => true)
      expect([a == 200, x == a.positive?]).to have_solution(x => false)
    end

    # Inherently signed
    it "negative?" do
      expect([a == 0, x == a.negative?]).to have_solution(x => false)
      expect([a == 100, x == a.negative?]).to have_solution(x => false)
      expect([a == 200, x == a.negative?]).to have_solution(x => true)
    end

    # Inherently signed
    it "abs" do
      expect([a == 0, b == a.abs]).to have_solution(b => 0)
      expect([a == 100, b == a.abs]).to have_solution(b => 100)
      expect([a == 200, b == a.abs]).to have_solution(b => 56)
    end
  end
end
