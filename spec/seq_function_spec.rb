module Z3
  describe SeqFunction do
    let(:int) { IntSort.new }
    let(:bool) { BoolSort.new }

    it "records the argument sorts and the range" do
      f = SeqFunction.from_block(int, int) { |a, x| a + x }
      expect(f.arg_sorts).to eq([int, int])
      expect(f.range).to eq(int)
    end

    it "takes the range from the block's result, whatever it is" do
      expect(SeqFunction.from_block(int, int) { |a, x| a > x }.range).to eq(bool)
      expect(SeqFunction.from_block(int, int, int) { |i, a, x| i + a + x }.range).to eq(int)
    end

    # The same casting `Z3.Lambda` does
    it "casts a Ruby literal body" do
      expect(SeqFunction.from_block(int, int) { |_a, _x| 7 }.range).to eq(int)
      expect(SeqFunction.from_block(int, int) { |_a, _x| true }.range).to eq(bool)
    end

    it "describes itself with its sorts" do
      expect(SeqFunction.from_block(int, int) { |a, x| a + x }.inspect)
        .to eq("Z3::SeqFunction<(Int, Int) -> Int>")
      expect(SeqFunction.from_block(int, bool) { |_a, b| b }.to_s)
        .to eq("Z3::SeqFunction<(Int, Bool) -> Bool>")
    end

    it "raises on the wrong number of block arguments" do
      expect { SeqFunction.from_block(int, int) { |a| a } }
        .to raise_error(Z3::Exception, "Block takes 1 argument, expected 2")
      expect { SeqFunction.from_block(int) { |a, x| a + x } }
        .to raise_error(Z3::Exception, "Block takes 2 arguments, expected 1")
    end

    it "raises without a block, or on anything but sorts" do
      expect { SeqFunction.from_block(int, int) }
        .to raise_error(Z3::Exception, "A function needs a block")
      expect { SeqFunction.from_block(int, Z3.Int("x")) { |a, x| a } }
        .to raise_error(Z3::Exception, "Argument sorts expected, got Z3::IntExpr")
    end

    # Deliberately not an Expr - a binary lambda is an `Array(Int, Int, Int)`, a sort
    # this gem has no representation for, and `Sort.from_pointer` would report it as
    # `Array(Int, Int)`. Holding the raw AST means there's nothing to be wrong about.
    it "is not an Expr, so it has no sort to lie about" do
      f = SeqFunction.from_block(int, int) { |a, x| a + x }
      expect(f).to_not be_a(Expr)
      expect(f).to_not respond_to(:sort)
    end

    # ...which is what the lie would have looked like
    it "avoids the wrong sort an Expr would have had" do
      acc, elem = Z3.Int("acc"), Z3.Int("elem")
      raw = Expr.new_from_pointer(LowLevel.mk_lambda_const([acc, elem], acc + elem))
      expect(raw.sort).to eq(ArraySort.new(int, int))
      expect { raw[3] }.to raise_error(Z3::Exception, /select requires 3 arguments/)
    end
  end
end
