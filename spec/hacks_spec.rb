module Z3
  # Ruby's core classes answer `==` themselves, and left to their own devices they
  # answer a plain `true` or `false` when the other side is an Expr - `1 == int_var`
  # would be `false` where `int_var == 1` builds an equation. `lib/z3/hacks.rb`
  # prepends modules to every core class which can stand for a Z3 value so both ways
  # round mean the same thing.
  #
  # That's what this file is about: not whether `==` works, which the per-sort specs
  # cover, but whether it works the same from either side. See issue #7.
  describe "Ruby core class hacks" do
    let(:int) { Z3.Int("i") }
    let(:real) { Z3.Real("r") }
    let(:bool) { Z3.Bool("b") }
    let(:bv) { Z3.Bitvec("v", 8) }
    let(:str) { Z3.String("s") }
    let(:float) { FloatSort.new(11, 53).var("f") }
    let(:char) { CharSort.new.var("ch") }
    # Named sorts are registered globally by name, so these are this file's own rather
    # than the `Color` and `Point` other specs declare with different values
    let(:enum) { EnumSort.new("HackColor", %i[red green]).var("c") }
    let(:point) { TupleSort.new("HackPoint", x: IntSort.new, y: IntSort.new).var("p") }

    # Every Ruby value which stands for something in Z3, against every sort which can
    # hold it. The pairs drive both the symmetry examples and the mismatch ones - the
    # combinations not listed here are the mismatches.
    def value_sort_pairs
      {
        1 => %i[int real bv float],
        1.5 => %i[int real float],
        Rational(1, 2) => %i[int real],
        true => %i[bool],
        false => %i[bool],
        "a" => %i[str],
        :red => %i[enum],
        [1, 2] => %i[point],
        {x: 1, y: 2} => %i[point],
      }
    end

    def all_exprs
      %i[int real bool bv str float char enum point]
    end

    describe "#==" do
      it "means the same thing with the Ruby value on either side" do
        value_sort_pairs.each do |value, sorts|
          sorts.each do |sort|
            expr = public_send(sort)
            expect(value == expr).to be_a(BoolExpr)
            expect(value == expr).to be_equivalent_to(expr == value)
          end
        end
      end

      it "builds an expression, not a Ruby boolean" do
        expect(1 == int).to be_a(BoolExpr)
        expect(true == bool).to be_a(BoolExpr)
        expect("a" == str).to be_a(BoolExpr)
        expect(:red == enum).to be_a(BoolExpr)
        expect([1, 2] == point).to be_a(BoolExpr)
        expect({x: 1, y: 2} == point).to be_a(BoolExpr)
      end
    end

    describe "#!=" do
      it "means the same thing with the Ruby value on either side" do
        value_sort_pairs.each do |value, sorts|
          sorts.each do |sort|
            expr = public_send(sort)
            expect(value != expr).to be_a(BoolExpr)
            expect(value != expr).to be_equivalent_to(expr != value)
          end
        end
      end

      # `!=` is a real method in Ruby, not `!` composed with `==`, so a class which
      # overrides only `==` gets a `!=` which contradicts it
      it "is the negation of #==" do
        value_sort_pairs.each do |value, sorts|
          sorts.each do |sort|
            expr = public_send(sort)
            expect(value != expr).to be_equivalent_to(~(value == expr))
          end
        end
      end
    end

    describe "ordering" do
      # Bitvectors are missing because they have no bare `<` - signed and unsigned
      # have to be asked for by name - and Bools, enums and tuples have no order at all
      let(:ordered) { {int => 1, real => 1.5, str => "a"} }

      it "flips round to the matching operator with the Ruby value on the left" do
        {:< => :>, :<= => :>=, :> => :<, :>= => :<=}.each do |op, flipped|
          ordered.each do |expr, value|
            expect(value.public_send(op, expr))
              .to be_equivalent_to(expr.public_send(flipped, value))
          end
        end
      end

      it "leaves Ruby's own comparisons alone" do
        expect(1 < 2).to eq(true)
        expect(1.5 >= 2).to eq(false)
        expect(Rational(1, 2) < 1).to eq(true)
        expect("a" < "b").to eq(true)
        expect(1 <=> 2).to eq(-1)
      end
    end

    # Ruby's coercion protocol recasts both sides into the wider sort, rather than
    # converting the Expr up to meet a value which was going to be cast anyway
    describe "coercion" do
      it "casts the Ruby value into the sort instead of converting the Expr" do
        expect(1 + real).to stringify("1 + r")
        expect(2 * real).to stringify("2 * r")
      end

      it "widens the Expr when the Ruby value needs it" do
        expect(1.5 + int).to stringify("(3/2) + to_real(i)")
      end

      it "is available on every Expr, not only the arithmetic ones" do
        expect(str.coerce("a").map(&:sort)).to eq([StringSort.new, StringSort.new])
        expect(point.coerce([1, 2]).map(&:sort)).to eq([point.sort, point.sort])
      end

      it "returns the Ruby value first, as Ruby's protocol wants" do
        value, expr = int.coerce(1)
        expect(value).to be_same_as(IntSort.new.from_const(1))
        expect(expr).to be_same_as(int)
      end
    end

    describe "sort mismatches" do
      it "fail identically whichever side the Ruby value is on" do
        value_sort_pairs.each do |value, sorts|
          (all_exprs - sorts).each do |sort|
            expr = public_send(sort)
            from_expr = (expr == value rescue $!)
            from_value = (value == expr rescue $!)
            expect(from_expr).to be_a(::Exception)
            expect([from_value.class, from_value.message])
              .to eq([from_expr.class, from_expr.message]),
                  "#{value.inspect} == #{sort} said #{from_value.inspect}, " \
                  "but #{sort} == #{value.inspect} said #{from_expr.inspect}"
          end
        end
      end

      it "name the sorts rather than the Ruby classes" do
        expect { 1 == bool }.to raise_error(ArgumentError, "Can't convert Int into Bool")
        expect { 1.5 == bv }.to raise_error(ArgumentError, "Can't convert Real into Bitvec(8)")
        expect { 1 == char }.to raise_error(ArgumentError, "Can't convert Int into Char")
        expect { "a" == int }.to raise_error(ArgumentError, "Can't convert String into Int")
      end

      it "say so about values with no sort of their own" do
        expect { [1, 2] == int }.to raise_error(Z3::Exception, "Array can't be coerced into Int")
        expect { {x: 1} == str }.to raise_error(Z3::Exception, "Hash can't be coerced into String")
      end
    end

    # The prepended modules sit in front of `==` on classes used by every Ruby program
    # in existence, so the fall-through matters at least as much as the Z3 path
    describe "ordinary Ruby comparisons" do
      it "still work on every hacked class" do
        expect(1 == 1).to eq(true)
        expect(1 == 2).to eq(false)
        expect(1 == 1.0).to eq(true)
        expect(1.5 == Rational(3, 2)).to eq(true)
        expect(true == true).to eq(true)
        expect(true == false).to eq(false)
        expect("a" == "a").to eq(true)
        expect(:a == :a).to eq(true)
        expect([1, [2]] == [1, [2]]).to eq(true)
        expect([1, 2] == [2, 1]).to eq(false)
        expect({x: 1} == {x: 1}).to eq(true)
        expect({x: 1} == {x: 2}).to eq(false)
      end

      it "still work against unrelated objects" do
        expect(1 == "a").to eq(false)
        expect([1, 2] == nil).to eq(false)
        expect({x: 1} == Object.new).to eq(false)
        expect(1 != "a").to eq(true)
      end

      it "keep Hash and Array using the values inside them" do
        expect([1, 2].include?(2)).to eq(true)
        expect([[1], [2]].index([2])).to eq(1)
        expect({[1, 2] => :x}[[1, 2]]).to eq(:x)
      end
    end

    # Documented rather than fixed, so a change here is a decision and not a surprise
    describe "what deliberately isn't hacked" do
      # `nil == expr` has to answer either `false` or an exception, and Ruby asks it on
      # its own, where an exception would stop the whole call rather than the element
      it "leaves nil and plain Objects answering Ruby booleans" do
        expect(nil == int).to eq(false)
        expect(nil != int).to eq(true)
        expect(Object.new == int).to eq(false)
        # Which is what lets this get as far as the 1, truthy answer and all
        expect([nil, 1].include?(int)).to eq(true)
      end

      it "still refuses them from the Expr side" do
        expect { int == nil }.to raise_error(Z3::Exception, "nil can't be coerced into Int")
      end

      # The rest of this block is what API.md's "Ruby integration and its limits"
      # section claims, so that the claims are checked rather than just written down.
      #
      # Ruby's own `==` on containers is C code which wants a `true` or a `false`, and
      # an Expr is neither - it's an object, so it's truthy, so any two Exprs look
      # equal. Nothing a core class hack can reach.
      let(:a) { Z3.Int("a") }
      let(:b) { Z3.Int("b") }
      let(:c) { Z3.Int("c") }

      it "can't stop == searches finding the first thing they look at" do
        expect([a] == [b]).to eq(true)
        expect([a].include?(b)).to eq(true)
        expect([a, b].index(b)).to eq(0)
        expect([a, b].count(b)).to eq(2)
        expect([a, b].tap { |ary| ary.delete(b) }).to eq([])
        expect({x: a} == {x: b}).to eq(true)
        expect({1 => a}.value?(b)).to eq(true)
      end

      # `Object#===` is `==`, and `Object#<=>` answers 0 whenever `==` is truthy
      it "can't stop case/when and sorting either" do
        expect(case a when b then :matched else :no end).to eq(:matched)
        expect([b, a].sort).to be_same_as([b, a])
        expect([b, a].min).to be_same_as(b)
      end

      it "has the same problem with the Ruby value on the left" do
        expect([1].include?(a)).to eq(true)
        expect([1, 2].index(a)).to eq(0)
      end

      # Z3 interns its ASTs, so eql? is both cheap and exactly "the same term"
      it "is fine wherever Ruby uses eql? and hash instead" do
        expect({a => 1, b => 2}[b]).to eq(2)
        expect({a => 1}.key?(b)).to eq(false)
        expect(Set[a, b].include?(a)).to eq(true)
        expect(Set[a, b].include?(c)).to eq(false)
        expect([a, b].uniq.size).to eq(2)
        expect([a, a].uniq.size).to eq(1)
        expect([a, b] - [b]).to eq([a])
        expect([a, b] & [b, c]).to eq([b])
        expect(([a, b] | [b, c]).size).to eq(3)
        expect([a, b, a].tally.size).to eq(2)
        expect([a, b, a].group_by { |x| x }.size).to eq(2)
      end

      it "keeps hashing safe with the Ruby value on the left too" do
        expect(Set[1].include?(a)).to eq(false)
        expect({1 => :x}[a]).to eq(nil)
      end

      it "answers eql? by term, not by value" do
        expect((a + 1).eql?(a + 1)).to eq(true)
        expect((a + 1).eql?(1 + a)).to eq(false)
        expect(a.eql?(b)).to eq(false)
        expect([a, b].index { |x| x.eql?(b) }).to eq(1)
      end
    end
  end
end
