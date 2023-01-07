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
        c => float_double.from_const(7.5),
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

      # Denormals changed
      if Z3.version_at_least?(4, 6)
        expect(float_double.from_const(1234 * 0.5**1040).to_s).to eq("0.00470733642578125B-1022")
        expect(float_single.from_const(1234 * 0.5**136).to_s).to eq("1.205078125B-126")
        # This is what we get, all of these are wrong, by a lot:
        # expect(float_single.from_const(1234 * 0.5**137).to_s).to eq("0.205078125B-126")
        # expect(float_single.from_const(1234 * 0.5**138).to_s).to eq("0.205078125B-126")
        # expect(float_single.from_const(1234 * 0.5**139).to_s).to eq("0.205078125B-126")
        #
        # It's not even a bug in printer Z3_mk_fpa_numeral_double is broken for denormals
        #
        # Probably best revisit it in 4.7+
      else
        expect(float_double.from_const(1234 * 0.5**1040).to_s).to eq("1.205078125B-1030")
      end
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
