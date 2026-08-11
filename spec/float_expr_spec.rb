module Z3
  describe FloatExpr do
    let(:mode) { RoundingModeSort.new }
    let(:float_single) { FloatSort.new(:single) }
    let(:float_double) { FloatSort.new(:double) }
    let(:a) { float_double.var("a") }
    let(:b) { float_double.var("b") }
    let(:c) { float_double.var("c") }
    let(:m) { mode.var("m") }
    let(:x) { BoolSort.new.var("x") }

    let(:positive_zero) { float_double.positive_zero }
    let(:negative_zero) { float_double.negative_zero }
    let(:positive_infinity) { float_double.positive_infinity }
    let(:negative_infinity) { float_double.negative_infinity }
    let(:nan) { float_double.nan }

    it "+" do
      expect([a == 2.0, b == 4.0, c == a.add(b,m)]).to have_solution(
        c => float_double.from_const(6.0),
      )
    end

    it "*" do
      expect([a == -2.0, b == 0.5, c == a.mul(b,m)]).to have_solution(
        c => float_double.from_const(-1.0),
      )
    end

    it "-" do
      expect([a == 2.0, b == 0.5, c == a.sub(b,m)]).to have_solution(
        c => float_double.from_const(1.5),
      )
    end

    it "/" do
      expect([a == 12.0, b == 3.0, c == a.div(b,m)]).to have_solution(
        c => float_double.from_const(4.0),
      )
    end

    it "%" do
      expect([a == 13.5, b == 3.0, c == a.rem(b)]).to have_solution(
        c => float_double.from_const(1.5),
      )
    end

    it "abs" do
      expect([a == 7.5, c == a.abs]).to have_solution(
        c => float_double.from_const(7.5),
      )
      expect([a == -7.5, c == a.abs]).to have_solution(
        c => float_double.from_const(7.5),
      )
    end

    it "neg" do
      expect([a == 7.5, c == -a]).to have_solution(
        c => float_double.from_const(-7.5),
      )
      expect([a == -7.5, c == -a]).to have_solution(
        c => float_double.from_const(7.5),
      )
    end

    # Broken in z3 before 4.6
    it "max" do
      expect([a == 2.0, b == 3.0, c == a.max(b)]).to have_solution(
        c => float_double.from_const(3.0),
      )
    end

    it "min" do
      expect([a == 2.0, b == 3.0, c == a.min(b)]).to have_solution(
        c => float_double.from_const(2.0),
      )
    end

    # These need a concrete rounding mode, unlike `m` which the solver picks
    let(:ties_even) { mode.nearest_ties_even }
    let(:to_zero) { mode.towards_zero }

    it "sqrt" do
      expect([a == 9.0, c == a.sqrt(ties_even)]).to have_solution(
        c => float_double.from_const(3.0),
      )
      expect([a == 2.0, c == a.sqrt(ties_even)]).to have_solution(
        c => float_double.from_const(Math.sqrt(2)),
      )
      expect{ a.sqrt(:nearest_ties_even) }.to raise_error(Z3::Exception, "Mode expected")
    end

    # Which way a tie goes is the rounding mode's business, not this method's
    it "round_to_integral" do
      expect([a ==  2.5, c == a.round_to_integral(ties_even)]).to have_solution(c => float_double.from_const(2.0))
      expect([a ==  3.5, c == a.round_to_integral(ties_even)]).to have_solution(c => float_double.from_const(4.0))
      expect([a ==  2.9, c == a.round_to_integral(to_zero)]).to have_solution(c => float_double.from_const(2.0))
      expect([a == -2.9, c == a.round_to_integral(to_zero)]).to have_solution(c => float_double.from_const(-2.0))
      expect{ a.round_to_integral(:towards_zero) }.to raise_error(Z3::Exception, "Mode expected")
    end

    it "fused_multiply_add" do
      d = float_double.var("d")
      expect([a == 2.0, b == 3.0, c == 1.0, d == a.fused_multiply_add(b, c, ties_even)]).to have_solution(
        d => float_double.from_const(7.0),
      )
      expect{ a.fused_multiply_add(b, c, :nearest_ties_even) }.to raise_error(Z3::Exception, "Mode expected")
    end

    # Exact, where the other direction rounds - every float is a Real.
    #
    # Simplified rather than solved like everything else in this file, because Z3
    # 4.16 gets fp.to_real wrong as soon as it meets a Real constraint: asserting
    # `r == a.to_real` with `a == 0.5` gives a model saying `r = 2`, in which that
    # same constraint evaluates to false. The term built here is right, and
    # simplifying it shows that without going near the part Z3 breaks on.
    it "to_real" do
      expect(float_double.from_const(2.5).to_real.simplify).to stringify("5/2")
      expect(float_double.from_const(-0.5).to_real.simplify).to stringify("-1/2")
      expect(float_double.from_const(-7.25).to_real.simplify).to stringify("-29/4")
      expect(float_double.from_const(-3.0).to_real.simplify).to stringify("-3")
      expect(float_double.from_const(0.0).to_real.simplify).to stringify("0")
      expect(a.to_real.sort).to eq(RealSort.new)
    end

    it "to_ieee_bv" do
      f = float_single.var("f")
      bv = Z3.Bitvec("bv", 32)
      expect([f == 1.0, bv == f.to_ieee_bv]).to have_solution(bv => 0x3F800000)
      expect([f == -2.0, bv == f.to_ieee_bv]).to have_solution(bv => 0xC0000000)
      expect(f.to_ieee_bv.sort).to eq(BitvecSort.new(32))
      expect(a.to_ieee_bv.sort).to eq(BitvecSort.new(64))
    end

    # Rounds to an integer, where #to_ieee_bv reinterprets the very same bits
    it "to_signed_bv / to_unsigned_bv" do
      bv = Z3.Bitvec("bv", 8)
      expect([a ==  2.9, bv == a.to_unsigned_bv(8, to_zero)]).to have_solution(bv => 2)
      expect([a ==  2.9, bv == a.to_signed_bv(8, to_zero)]).to have_solution(bv => 2)
      expect([a == -2.5, bv == a.to_signed_bv(8, to_zero)]).to have_solution(bv => 254)
      expect([a ==  2.5, bv == a.to_unsigned_bv(8, ties_even)]).to have_solution(bv => 2)
      expect(a.to_signed_bv(8, to_zero).sort).to eq(BitvecSort.new(8))
      expect{ a.to_bv(8, ties_even) }.to raise_error(Z3::Exception, /to_signed_bv/)
      expect{ a.to_signed_bv(8, :towards_zero) }.to raise_error(Z3::Exception, "Mode expected")
    end

    # The width is a decl parameter, not an argument, so without spelling it out
    # `a.to_signed_bv(8, m)` and `a.to_signed_bv(16, m)` were the same string. The
    # `to_fp` direction deliberately stays bare - its parameters are the result sort,
    # which `#sort` answers, the same call `NaN` makes.
    it "to_signed_bv / to_unsigned_bv print their width" do
      expect(a.to_signed_bv(32, ties_even).to_s).to eq("fp.to_sbv(roundNearestTiesToEven, a, 32)")
      expect(a.to_unsigned_bv(16, ties_even).to_s).to eq("fp.to_ubv(roundNearestTiesToEven, a, 16)")
      expect(a.to_signed_bv(16, ties_even).to_s).to_not eq(a.to_signed_bv(32, ties_even).to_s)
    end

    # The pieces #exponent_string and #significand_string give as Strings, as Bitvecs.
    # The significand is one narrower than sbits - IEEE doesn't store the leading bit.
    it "sign_bv / exponent_bv / significand_bv" do
      f = float_single.from_const(1.0)
      expect(f.sign_bv.sort).to eq(BitvecSort.new(1))
      expect(f.exponent_bv(true).sort).to eq(BitvecSort.new(8))
      expect(f.significand_bv.sort).to eq(BitvecSort.new(23))
      expect(f.sign_bv.unsigned_value).to eq(0)
      expect(f.exponent_bv(true).unsigned_value).to eq(127)
      expect(f.significand_bv.unsigned_value).to eq(0)
      expect(float_single.from_const(-1.0).sign_bv.unsigned_value).to eq(1)
    end

    # A Ruby Float is an IEEE double, so a double or narrower always converts
    it "value" do
      expect(float_double.from_const(1.5).value).to eq(1.5)
      expect(float_double.from_const(-7.25).value).to eq(-7.25)
      expect(float_double.from_const(0.1).value).to eq(0.1)
      expect(float_double.from_const(Float::MAX).value).to eq(Float::MAX)
      expect(float_single.from_const(0.1).value).to eq(0.10000000149011612)
      expect(FloatSort.new(:half).from_const(1.5).value).to eq(1.5)
      expect(float_double.from_const(1.5).value).to be_a(Float)
    end

    # Subnormals go through the same code, with the significand below 1 and the
    # exponent stuck at the sort's minimum
    it "value of subnormals" do
      expect(float_double.from_const(1234 * 0.5**1040).value).to eq(1234 * 0.5**1040)
      expect(float_single.from_const(1234 * 0.5**137).value).to eq(1234 * 0.5**137)
      expect(FloatSort.new(:half).from_const(2.0**-24).value).to eq(2.0**-24)
    end

    # Ruby has all of these too, and the two zeroes are different Floats
    it "value of zeroes, infinities and NaN" do
      expect(positive_zero.value).to eq(0.0)
      expect(negative_zero.value).to eq(-0.0)
      expect(1 / positive_zero.value).to eq(Float::INFINITY)
      expect(1 / negative_zero.value).to eq(-Float::INFINITY)
      expect(positive_infinity.value).to eq(Float::INFINITY)
      expect(negative_infinity.value).to eq(-Float::INFINITY)
      expect(nan.value).to be_nan
    end

    # It's the sort which has to fit, not the value - a quadruple's 1.5 would convert
    # exactly, but a sort a Float can't round-trip doesn't get a #value which works
    # only for the values which happen to be small enough
    it "value of sorts wider than a double" do
      quad = FloatSort.new(:quadruple)
      expect{ quad.from_const(1.5).value }.to raise_error(Z3::Exception, /Float\(15, 113\) values don't fit in a Ruby Float/)
      expect{ quad.nan.value }.to raise_error(Z3::Exception, /don't fit in a Ruby Float/)
      expect{ quad.var("q").value }.to raise_error(Z3::Exception, /don't fit in a Ruby Float/)
      # Only one of the two has to be too wide
      expect{ FloatSort.new(12, 53).from_const(1.5).value }.to raise_error(Z3::Exception, /don't fit/)
      expect{ FloatSort.new(11, 54).from_const(1.5).value }.to raise_error(Z3::Exception, /don't fit/)
      expect(FloatSort.new(11, 53).from_const(1.5).value).to eq(1.5)
      expect(FloatSort.new(8, 24).from_const(1.5).value).to eq(1.5)
    end

    # Every float literal is an `:app`, so this can't lean on #ast_kind
    it "value of expressions" do
      expect(float_double.from_const(2.0).add(float_double.from_const(0.5), ties_even).value).to eq(2.5)
      expect{ a.value }.to raise_error(Z3::Exception, "Can't convert expression a into a Float")
      expect{ a.add(b, ties_even).value }.to raise_error(Z3::Exception, /Can't convert expression/)
    end

    it "value out of a model" do
      solver = Solver.new
      solver.assert a == 1.25
      solver.check
      expect(solver.model[a].value).to eq(1.25)
    end

    it "comparisons" do
      expect([a == 3.0, b == 3.0, x == (a >= b)]).to have_solution(x => true)
      expect([a == 3.0, b == 3.0, x == (a >  b)]).to have_solution(x => false)
      expect([a == 3.0, b == 3.0, x == (a <= b)]).to have_solution(x => true)
      expect([a == 3.0, b == 3.0, x == (a <  b)]).to have_solution(x => false)
      expect([a == 3.0, b == 3.0, x == (a == b)]).to have_solution(x => true)
      expect([a == 3.0, b == 3.0, x == (a != b)]).to have_solution(x => false)

      expect([a == 3.0, b == 2.0, x == (a >= b)]).to have_solution(x => true)
      expect([a == 3.0, b == 2.0, x == (a >  b)]).to have_solution(x => true)
      expect([a == 3.0, b == 2.0, x == (a <= b)]).to have_solution(x => false)
      expect([a == 3.0, b == 2.0, x == (a <  b)]).to have_solution(x => false)
      expect([a == 3.0, b == 2.0, x == (a == b)]).to have_solution(x => false)
      expect([a == 3.0, b == 2.0, x == (a != b)]).to have_solution(x => true)
    end

    # This isn't the most amazing format ever, probably reevaluate it completely at some point
    it "to_s" do
      expect(float_double.from_const(1.0).to_s).to eq("1B+0")
      expect(float_double.from_const(2.0).to_s).to eq("1B+1")
      expect(float_double.from_const(0.5).to_s).to eq("1B-1")
      expect(positive_zero.to_s).to eq("+zero")
      expect(negative_zero.to_s).to eq("-zero")
      expect(positive_infinity.to_s).to eq("+oo")
      expect(negative_infinity.to_s).to eq("-oo")
      expect(nan.to_s).to eq("NaN")

      # Denormals
      expect(float_double.from_const(1234 * 0.5**1040).to_s).to eq("0.00470733642578125B-1022")
      expect(float_single.from_const(1234 * 0.5**136).to_s).to eq("1.205078125B-126")
      # These used to come out as "0.205078125B-126", wrong by a lot, because
      # Z3_mk_fpa_numeral_double misencodes denormals. from_const rounds with
      # fp.to_fp now, so each of these is exactly 1234 * 2**-k
      expect(float_single.from_const(1234 * 0.5**137).to_s).to eq("0.6025390625B-126")
      expect(float_single.from_const(1234 * 0.5**138).to_s).to eq("0.30126953125B-126")
      expect(float_single.from_const(1234 * 0.5**139).to_s).to eq("0.150634765625B-126")
    end

    it "to_s of negative numerals" do
      expect(float_double.from_const(-1.0).to_s).to eq("-1B+0")
      expect(float_double.from_const(-2.0).to_s).to eq("-1B+1")
      expect(float_double.from_const(-0.5).to_s).to eq("-1B-1")
      expect(float_double.from_const(-7.5).to_s).to eq("-1.875B+2")
      expect(float_single.from_const(-1.5).to_s).to eq("-1.5B+0")
    end

    it "zero?" do
      expect([x == positive_zero.zero?]).to have_solution(x => true)
      expect([x == negative_zero.zero?]).to have_solution(x => true)
      expect([x == positive_infinity.zero?]).to have_solution(x => false)
      expect([x == negative_infinity.zero?]).to have_solution(x => false)
      expect([x == float_double.from_const(1.5).zero?]).to have_solution(x => false)
      expect([x == nan.zero?]).to have_solution(x => false)
    end

    # Same as positive or negative
    # +0, -0, and NaN are all false
    it "nonzero?" do
      expect([x == positive_zero.nonzero?]).to have_solution(x => false)
      expect([x == negative_zero.nonzero?]).to have_solution(x => false)
      expect([x == positive_infinity.nonzero?]).to have_solution(x => true)
      expect([x == negative_infinity.nonzero?]).to have_solution(x => true)
      expect([x == float_double.from_const(1.5).nonzero?]).to have_solution(x => true)
      expect([x == nan.nonzero?]).to have_solution(x => false)
    end

    it "infinite?" do
      expect([x == positive_zero.infinite?]).to have_solution(x => false)
      expect([x == positive_infinity.infinite?]).to have_solution(x => true)
      expect([x == negative_infinity.infinite?]).to have_solution(x => true)
      expect([x == float_double.from_const(1.5).infinite?]).to have_solution(x => false)
      expect([x == nan.infinite?]).to have_solution(x => false)
    end

    it "nan?" do
      expect([x == positive_zero.nan?]).to have_solution(x => false)
      expect([x == positive_infinity.nan?]).to have_solution(x => false)
      expect([x == float_double.from_const(1.5).nan?]).to have_solution(x => false)
      expect([x == nan.nan?]).to have_solution(x => true)
    end

    it "normal?" do
      expect([x == positive_zero.normal?]).to have_solution(x => false)
      expect([x == positive_infinity.normal?]).to have_solution(x => false)
      expect([x == nan.normal?]).to have_solution(x => false)
      expect([x == float_double.from_const(1.5).normal?]).to have_solution(x => true)
      expect([x == float_double.from_const(1234 * 0.5**1040).normal?]).to have_solution(x => false)
    end

    it "subnormal?" do
      expect([x == positive_zero.subnormal?]).to have_solution(x => false)
      expect([x == positive_infinity.subnormal?]).to have_solution(x => false)
      expect([x == nan.subnormal?]).to have_solution(x => false)
      expect([x == float_double.from_const(1.5).subnormal?]).to have_solution(x => false)
      expect([x == float_double.from_const(1234 * 0.5**1040).subnormal?]).to have_solution(x => true)
    end

    it "positive?" do
      expect([x == positive_zero.positive?]).to have_solution(x => true)
      expect([x == negative_zero.positive?]).to have_solution(x => false)
      expect([x == positive_infinity.positive?]).to have_solution(x => true)
      expect([x == negative_infinity.positive?]).to have_solution(x => false)
      expect([x == float_double.from_const(1.5).positive?]).to have_solution(x => true)
      expect([x == float_double.from_const(-1.5).positive?]).to have_solution(x => false)
      expect([x == nan.positive?]).to have_solution(x => false)
    end

    it "negative?" do
      expect([x == positive_zero.negative?]).to have_solution(x => false)
      expect([x == negative_zero.negative?]).to have_solution(x => true)
      expect([x == positive_infinity.negative?]).to have_solution(x => false)
      expect([x == negative_infinity.negative?]).to have_solution(x => true)
      expect([x == float_double.from_const(1.5).negative?]).to have_solution(x => false)
      expect([x == float_double.from_const(-1.5).negative?]).to have_solution(x => true)
      expect([x == nan.negative?]).to have_solution(x => false)
    end

    # We can't simply do have_solution(b => positive_zero)
    # as positive_zero == negative_zero
    it "abs" do
      expect([a == positive_zero, b == a.abs]).to have_solution(a.abs => positive_zero)
      expect([a == negative_zero, b == a.abs]).to have_solution(a.abs => positive_zero)
      expect([a == positive_infinity, b == a.abs]).to have_solution(b => positive_infinity)
      expect([a == negative_infinity, b == a.abs]).to have_solution(b => positive_infinity)
      expect([a == float_double.from_const(1.5), b == a.abs]).to have_solution(b => float_double.from_const(1.5))
      expect([a == float_double.from_const(-1.5), b == a.abs]).to have_solution(b => float_double.from_const(1.5))
      expect([a == nan, b == a.abs]).to have_no_solution
    end

    # This means you need to be extra careful when using Z3::Float
    # as == means something else on them than mathematical ==
    #
    # Also have_solutions helper doesn't work as it relies on ==
    it "zeroes" do
      expect([a == positive_zero, b == a, b.positive?]).to have_solution(b => positive_zero)
      expect([a == negative_zero, b == a, b.negative?]).to have_solution(b => negative_zero)
      expect([a == positive_zero, b == a, b.positive?]).to have_solution(b => positive_zero)
      expect([a == negative_zero, b == a, b.negative?]).to have_solution(b => negative_zero)
    end
  end
end
