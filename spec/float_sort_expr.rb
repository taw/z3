module Z3
  describe FloatExpr do
    let(:mode) { RoundingModeSort.new }
    let(:float_double) { FloatSort.new(:double) }
    let(:a) { float_double.var("a") }
    let(:b) { float_double.var("b") }
    let(:c) { float_double.var("c") }
    let(:m) { mode.var("m") }

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
  end
end
