module Z3
  describe FloatSort do
    let(:float_16)        { FloatSort.new(16) }
    let(:float_32)        { FloatSort.new(32) }
    let(:float_64)        { FloatSort.new(64) }
    let(:float_128)       { FloatSort.new(128) }
    let(:float_half)      { FloatSort.new(:half) }
    let(:float_single)    { FloatSort.new(:single) }
    let(:float_double)    { FloatSort.new(:double) }
    let(:float_quadruple) { FloatSort.new(:quadruple) }
    let(:float_5_11)      { FloatSort.new(5, 11) }
    let(:float_8_24)      { FloatSort.new(8, 24) }
    let(:float_11_53)     { FloatSort.new(11, 53) }
    let(:float_15_113)    { FloatSort.new(15, 113) }

    it "to_s" do
      expect(float_5_11.to_s).to eq("Float(5, 11)")
      expect(float_15_113.to_s).to eq("Float(15, 113)")
    end

    it "inspect" do
      expect(float_5_11.inspect).to eq("FloatSort(5, 11)")
      expect(float_15_113.inspect).to eq("FloatSort(15, 113)")
    end

    it "sbits" do
      expect(float_8_24.sbits).to eq(24)
      expect(float_11_53.sbits).to eq(53)
    end

    it "ebits" do
      expect(float_8_24.ebits).to eq(8)
      expect(float_11_53.ebits).to eq(11)
    end

    it "shortcut syntax" do
      expect([float_16, float_32, float_64, float_128]).to be_all_different
      expect([float_16, float_half, float_5_11]).to be_all_same
      expect([float_32, float_single, float_8_24]).to be_all_same
      expect([float_64, float_double, float_11_53]).to be_all_same
      expect([float_128, float_quadruple, float_15_113]).to be_all_same
    end

    it "rejects unknown shortcuts" do
      expect{ FloatSort.new(:octuple) }.to raise_error(Z3::Exception, /Unknown float type octuple/)
      expect{ FloatSort.new(42) }.to raise_error(Z3::Exception, /Unknown float type 42/)
    end

    describe "#from_const" do
      it "overflows to a signed infinity" do
        expect(float_single.from_const(1e300).to_s).to eq("+oo")
        expect(float_single.from_const(-1e300).to_s).to eq("-oo")
        # half's largest finite value is 65504
        expect(float_half.from_const(70000.0).to_s).to eq("+oo")
        expect(float_half.from_const(-70000.0).to_s).to eq("-oo")
        expect(float_half.from_const(65504.0).to_s).to eq("1.9990234375B+15")
      end

      it "underflows to a signed zero" do
        expect(float_single.from_const(1e-300).to_s).to eq("+zero")
        expect(float_single.from_const(-1e-300).to_s).to eq("-zero")
        expect(float_half.from_const(1e-30).to_s).to eq("+zero")
      end

      it "keeps values which fit" do
        expect(float_single.from_const(1.5).to_s).to eq("1.5B+0")
        expect(float_single.from_const(-7.25).to_s).to eq("-1.8125B+2")
        expect(float_double.from_const(1e300).to_s).to eq("1.49322178960515028478539534262381494045257568359375B+996")
        expect(float_single.from_const(3.4028234663852886e38).to_s).to eq("1.99999988079071044921875B+127")
      end

      it "passes through zeroes, infinities and NaN" do
        expect(float_single.from_const(0.0).to_s).to eq("+zero")
        expect(float_single.from_const(-0.0).to_s).to eq("-zero")
        expect(float_single.from_const(Float::INFINITY).to_s).to eq("+oo")
        expect(float_single.from_const(-Float::INFINITY).to_s).to eq("-oo")
        expect(float_single.from_const(Float::NAN).to_s).to eq("NaN")
      end

      # Ruby's pack("f") rounds a double to IEEE single exactly as C would,
      # so rounding first must give the same result as converting directly
      it "rounds to nearest, like Ruby and C do" do
        [0.1, 0.2, 3.14159265358979, 1e-30, 1e30, -0.1, 2.0**-140, 2.0**-149,
         1234 * 0.5**137, 1e-45, 3.5e38].each do |val|
          rounded = [val].pack("f").unpack1("f")
          expect(float_single.from_const(val).to_s).to eq(float_single.from_const(rounded).to_s),
            "#{val} did not round to nearest single"
        end
      end

      it "returns a numeral, not an unfolded conversion" do
        skip "Z3_fpa_is_numeral was added in Z3 4.15.5" unless Z3.version_at_least?(4, 15, 5)
        [1e300, 1e-300, 0.1, 1.5, 1234 * 0.5**137].each do |val|
          expect(LowLevel.fpa_is_numeral(float_single.from_const(val))).to be true
        end
      end

      it "is usable in constraints" do
        x = float_single.var("x")
        # 1e300 used to encode as NaN, so x < 1e300 came out unsat for every x
        expect([x < 1e300, x == 1.0]).to have_solution(x => float_single.from_const(1.0))
        # 1e300 is +oo in single, and nothing is greater than +oo
        expect([x > 1e300]).to have_no_solution
      end

      it "converts Integers which fit a double exactly" do
        expect(float_single.from_const(2).to_s).to eq("1B+1")
        expect(float_double.from_const(-1024).to_s).to eq("-1B+10")
        expect{ float_double.from_const(2**53 + 1) }.to raise_error(Z3::Exception, "Out of range")
      end

      it "rejects everything else" do
        expect{ float_single.from_const("1.5") }.to raise_error(Z3::Exception, "Can't convert String into Float(8, 24)")
        expect{ float_single.from_const(Rational(1, 3)) }.to raise_error(Z3::Exception, "Can't convert Rational into Float(8, 24)")
        # Ruby names nil / true / false rather than their classes, and so do we
        expect{ float_single.from_const(nil) }.to raise_error(Z3::Exception, "Can't convert nil into Float(8, 24)")
      end
    end

    # Everything below builds a value of this sort out of some other expression
    describe "building from other sorts" do
      let(:ties_even) { RoundingModeSort.new.nearest_ties_even }

      # Reinterprets the bits, so it's FloatExpr#to_ieee_bv backwards
      it "#from_ieee_bv" do
        expect(float_single.from_ieee_bv(BitvecSort.new(32).from_const(0x3F800000)).simplify).to stringify("1B+0")
        expect(float_single.from_ieee_bv(BitvecSort.new(32).from_const(0xC0000000)).simplify).to stringify("-1B+1")
        expect(float_single.from_ieee_bv(float_single.from_const(-7.25).to_ieee_bv).simplify)
          .to stringify(float_single.from_const(-7.25).to_s)
      end

      it "#from_ieee_bv wants a Bitvec of exactly the sort's width" do
        expect{ float_single.from_ieee_bv(BitvecSort.new(8).from_const(1)) }
          .to raise_error(Z3::Exception, "Bitvec(32) expected as an IEEE bit pattern, got Bitvec(8)")
        expect{ float_single.from_ieee_bv(42) }
          .to raise_error(Z3::Exception, "Bitvec(32) expected as an IEEE bit pattern, got Integer")
      end

      # The three IEEE fields separately, which is #sign_bv / #exponent_bv /
      # #significand_bv backwards
      it "#from_components" do
        sign = BitvecSort.new(1).from_const(0)
        # 128 biased is an unbiased exponent of 1, and a zero significand means 1.0
        exponent = BitvecSort.new(8).from_const(128)
        significand = BitvecSort.new(23).from_const(0)
        expect(float_single.from_components(sign, exponent, significand).simplify).to stringify("1B+1")

        original = float_single.from_const(-7.25)
        expect(float_single.from_components(original.sign_bv, original.exponent_bv(true), original.significand_bv).simplify)
          .to stringify(original.to_s)
      end

      it "#from_components checks every width" do
        ok_sign = BitvecSort.new(1).from_const(0)
        ok_exponent = BitvecSort.new(8).from_const(128)
        ok_significand = BitvecSort.new(23).from_const(0)
        expect{ float_single.from_components(ok_exponent, ok_exponent, ok_significand) }
          .to raise_error(Z3::Exception, "Bitvec(1) expected as a sign, got Bitvec(8)")
        expect{ float_single.from_components(ok_sign, ok_sign, ok_significand) }
          .to raise_error(Z3::Exception, "Bitvec(8) expected as an exponent, got Bitvec(1)")
        # One narrower than sbits - IEEE doesn't store the leading bit
        expect{ float_single.from_components(ok_sign, ok_exponent, BitvecSort.new(24).from_const(0)) }
          .to raise_error(Z3::Exception, "Bitvec(23) expected as a significand, got Bitvec(24)")
      end

      it "#from_float rounds between float sorts" do
        expect(float_single.from_float(float_double.from_const(1.5), ties_even).simplify).to stringify("1.5B+0")
        expect{ float_single.from_float(1.5, ties_even) }.to raise_error(Z3::Exception, "Float expected")
        expect{ float_single.from_float(float_double.from_const(1.5), :ties_even) }.to raise_error(Z3::Exception, "Mode expected")
      end

      it "#from_real rounds a Real" do
        expect(float_double.from_real(Rational(1, 2), ties_even).simplify).to stringify("1B-1")
        expect(float_double.from_real(Z3.Real("r"), ties_even).sort).to eq(float_double)
        expect{ float_double.from_real(Rational(1, 2), :ties_even) }.to raise_error(Z3::Exception, "Mode expected")
      end

      # Reads the Bitvec as a number, where #from_ieee_bv reads the same bits as a
      # float already - so the same 8 bits give -3.0 signed and 253.0 unsigned
      it "#from_signed_bv / #from_unsigned_bv" do
        bits = BitvecSort.new(8).from_const(-3)
        expect(float_double.from_signed_bv(bits, ties_even).simplify).to stringify("-1.5B+1")
        expect(float_double.from_unsigned_bv(bits, ties_even).simplify).to stringify("1.9765625B+7")
        expect{ float_double.from_signed_bv(3, ties_even) }.to raise_error(Z3::Exception, "Bitvec expected")
        expect{ float_double.from_unsigned_bv(bits, :ties_even) }.to raise_error(Z3::Exception, "Mode expected")
      end

      it "#from_significand_and_exponent" do
        expect(float_double.from_significand_and_exponent(Rational(5, 4), 3, ties_even).simplify).to stringify("1.25B+3")
        expect(float_double.from_significand_and_exponent(1, 0, ties_even).simplify).to stringify("1B+0")
        expect{ float_double.from_significand_and_exponent(1, 0, :ties_even) }.to raise_error(Z3::Exception, "Mode expected")
      end
    end
  end
end
