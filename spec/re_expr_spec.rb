module Z3
  describe ReExpr do
    let(:sort) { ReSort.new(StringSort.new) }
    let(:int_seq) { SeqSort.new(IntSort.new) }
    let(:int_seq_re) { ReSort.new(int_seq) }
    let(:s) { Z3.String("s") }
    let(:xs) { int_seq.var("xs") }
    let(:lower) { Re.Range("a", "z") }

    it "Z3::Re is the same class" do
      expect(Re).to be(ReExpr)
    end

    describe ".Of" do
      it "is the regex matching exactly one string" do
        expect(Re.Of("ab").sexpr).to eq(%q{(str.to_re "ab")})
        expect(Re.Of("ab").sort).to eq(sort)
      end

      it "takes a StringExpr too" do
        expect(Re.Of(s).sexpr).to eq("(str.to_re s)")
        expect(Re.Of(s + "!").sexpr).to eq(%q{(str.to_re (str.++ s "!"))})
      end

      it "takes a SeqExpr" do
        expect(Re.Of(xs).sexpr).to eq("(seq.to.re xs)")
        expect(Re.Of(xs).sort).to eq(int_seq_re)
      end

      # A Ruby Array says nothing about its element sort, so that's the one case
      # which needs the sort spelled out
      it "takes a Ruby Array with an explicit sort" do
        expect(Re.Of([1, 2], int_seq).sexpr).to eq("(seq.to.re (seq.++ (seq.unit 1) (seq.unit 2)))")
        expect(Re.Of([1, 2], int_seq).sort).to eq(int_seq_re)
      end

      it "rejects a Ruby Array with no sort to go on" do
        expect { Re.Of([1, 2]) }.to raise_error(Z3::Exception)
      end

      it "leaves a Re alone" do
        expect(Re.Of(lower)).to be_same_as(lower)
      end

      it "matches only that one string" do
        expect([s.matches?(Re.Of("ab"))]).to have_solution(s => %q{"ab"})
        expect([s.matches?(Re.Of("ab")), s != "ab"]).to have_no_solution
      end
    end

    describe ".Range" do
      it "sexpr" do
        expect(lower.sexpr).to eq(%q{(re.range "a" "z")})
        expect(lower.sort).to eq(sort)
      end

      it "matches single characters in the range" do
        expect([s.matches?(lower), s == "q"]).to have_solution(s => %q{"q"})
        expect([s.matches?(lower), s == "Q"]).to have_no_solution
        expect([s.matches?(lower), s == "ab"]).to have_no_solution
      end

      it "rejects non-sequence arguments" do
        expect { Re.Range(1, 2) }.to raise_error(Z3::Exception)
      end
    end

    describe "#star" do
      it "sexpr" do
        expect(lower.star.sexpr).to eq(%q{(re.* (re.range "a" "z"))})
      end

      it "matches any number of repetitions, including none" do
        expect([s.matches?(lower.star), s == ""]).to have_solution(s => %q{""})
        expect([s.matches?(lower.star), s == "abc"]).to have_solution(s => %q{"abc"})
        expect([s.matches?(lower.star), s == "aBc"]).to have_no_solution
      end

      it "has a constructor spelling too" do
        expect(Re.Star("ab")).to be_same_as(Re.Of("ab").star)
      end
    end

    describe "#plus" do
      it "sexpr" do
        expect(lower.plus.sexpr).to eq(%q{(re.+ (re.range "a" "z"))})
      end

      it "needs at least one repetition" do
        expect([s.matches?(lower.plus), s == "a"]).to have_solution(s => %q{"a"})
        expect([s.matches?(lower.plus), s == ""]).to have_no_solution
      end

      it "has a constructor spelling too" do
        expect(Re.Plus("ab")).to be_same_as(Re.Of("ab").plus)
      end
    end

    describe "#option" do
      it "sexpr" do
        expect(lower.option.sexpr).to eq(%q{(re.opt (re.range "a" "z"))})
      end

      it "matches zero or one" do
        expect([s.matches?(lower.option), s == ""]).to have_solution(s => %q{""})
        expect([s.matches?(lower.option), s == "a"]).to have_solution(s => %q{"a"})
        expect([s.matches?(lower.option), s == "ab"]).to have_no_solution
      end

      it "has a constructor spelling too" do
        expect(Re.Option("ab")).to be_same_as(Re.Of("ab").option)
      end
    end

    describe "#+" do
      it "is concatenation" do
        expect((Re.Of("a") + Re.Of("b")).sexpr).to eq(%q{(re.++ (str.to_re "a") (str.to_re "b"))})
      end

      it "converts its argument" do
        expect(Re.Of("a") + "b").to be_same_as(Re.Of("a") + Re.Of("b"))
      end

      it "constrains the solution" do
        expect([s.matches?(lower + Re.Of("!")), s == "z!"]).to have_solution(s => %q{"z!"})
        expect([s.matches?(lower + Re.Of("!")), s == "!z"]).to have_no_solution
      end

      it "Concat takes any number of arguments" do
        expect(Re.Concat("a", "b", "c")).to be_same_as(Re.Of("a") + Re.Of("b") + Re.Of("c"))
        expect(Re.Concat("a")).to be_same_as(Re.Of("a"))
        expect { Re.Concat }.to raise_error(Z3::Exception)
      end
    end

    describe "#|" do
      it "is union" do
        expect((Re.Of("a") | Re.Of("b")).sexpr).to eq(%q{(re.union (str.to_re "a") (str.to_re "b"))})
      end

      it "constrains the solution" do
        expect([s.matches?(Re.Union("cat", "dog")), s == "cat"]).to have_solution(s => %q{"cat"})
        expect([s.matches?(Re.Union("cat", "dog")), s == "cow"]).to have_no_solution
      end

      it "Union takes any number of arguments" do
        expect(Re.Union("a")).to be_same_as(Re.Of("a"))
        expect { Re.Union }.to raise_error(Z3::Exception)
      end
    end

    describe "#&" do
      it "is intersection" do
        expect((Re.Of("a") & Re.Of("b")).sexpr).to eq(%q{(re.inter (str.to_re "a") (str.to_re "b"))})
      end

      # The thing a backtracking regex engine can't do
      it "constrains the solution" do
        three_lower = lower * 3
        has_q = Re.Full + Re.Of("q") + Re.Full
        expect([s.matches?(three_lower & has_q), s == "aqb"]).to have_solution(s => %q{"aqb"})
        expect([s.matches?(three_lower & has_q), s == "abc"]).to have_no_solution
      end

      it "Intersect takes any number of arguments" do
        expect(Re.Intersect("a")).to be_same_as(Re.Of("a"))
        expect { Re.Intersect }.to raise_error(Z3::Exception)
      end
    end

    describe "#-" do
      it "is difference" do
        expect((Re.Of("a") - Re.Of("b")).sexpr).to eq(%q{(re.diff (str.to_re "a") (str.to_re "b"))})
        expect(Re.Diff("a", "b")).to be_same_as(Re.Of("a") - Re.Of("b"))
      end

      it "constrains the solution" do
        expect([s.matches?(lower - Re.Of("q")), s == "a"]).to have_solution(s => %q{"a"})
        expect([s.matches?(lower - Re.Of("q")), s == "q"]).to have_no_solution
      end
    end

    describe "#~" do
      it "is complement" do
        expect((~Re.Of("a")).sexpr).to eq(%q{(re.comp (str.to_re "a"))})
        expect(Re.Complement("a")).to be_same_as(~Re.Of("a"))
      end

      it "constrains the solution" do
        expect([s.matches?(~lower.star), s == "aBc"]).to have_solution(s => %q{"aBc"})
        expect([s.matches?(~lower.star), s == "abc"]).to have_no_solution
      end
    end

    describe "#*" do
      it "repeats an exact number of times" do
        expect((Re.Of("a") * 3).sexpr).to eq(%q{((_ re.^ 3) (str.to_re "a"))})
        expect(Re.Power("a", 3)).to be_same_as(Re.Of("a") * 3)
      end

      it "repeats a Range of times" do
        expect((Re.Of("a") * (2..5)).sexpr).to eq(%q{((_ re.loop 2 5) (str.to_re "a"))})
        expect(Re.Loop("a", 2, 5)).to be_same_as(Re.Of("a") * (2..5))
      end

      it "an exclusive Range drops the last repetition" do
        expect(Re.Of("a") * (2...5)).to be_same_as(Re.Of("a") * (2..4))
      end

      # Z3 spells "no upper bound" as an upper bound of 0, and drops it from the decl
      it "an endless Range is an open upper bound" do
        expect((Re.Of("a") * (2..)).sexpr).to eq(%q{((_ re.loop 2) (str.to_re "a"))})
        expect(Re.Loop("a", 2)).to be_same_as(Re.Of("a") * (2..))
      end

      it "a beginless Range starts at zero" do
        expect(Re.Of("a") * (..5)).to be_same_as(Re.Of("a") * (0..5))
      end

      # ...which is why `re * (0..0)` can't go through `re.loop` at all
      it "zero to zero is the empty string, not everything" do
        expect([s.matches?(Re.Of("a") * (0..0)), s == ""]).to have_solution(s => %q{""})
        expect([s.matches?(Re.Of("a") * (0..0)), s == "a"]).to have_no_solution
      end

      it "constrains the solution" do
        expect([s.matches?(lower * 3), s == "abc"]).to have_solution(s => %q{"abc"})
        expect([s.matches?(lower * 3), s.length == 4]).to have_no_solution
        expect([s.matches?(lower * (2..4)), s == "abcd"]).to have_solution(s => %q{"abcd"})
        expect([s.matches?(lower * (2..4)), s.length == 5]).to have_no_solution
        expect([s.matches?(lower * (2..)), s == "abcdefghi"]).to have_solution(s => %q{"abcdefghi"})
        expect([s.matches?(lower * (2..)), s.length == 1]).to have_no_solution
      end

      it "rejects counts Z3 can't take" do
        expect { Re.Of("a") * -1 }.to raise_error(Z3::Exception)
        expect { Re.Of("a") * (5..2) }.to raise_error(Z3::Exception)
        expect { Re.Of("a") * "x" }.to raise_error(Z3::Exception)
        expect { Re.Of("a") * (Z3.Int("i")..3) }.to raise_error(Z3::Exception)
      end
    end

    describe ".Empty / .Full / .AllChar" do
      it "sexpr" do
        expect(Re.Empty.sexpr).to eq("re.none")
        expect(Re.Full.sexpr).to eq("re.all")
        expect(Re.AllChar.sexpr).to eq("re.allchar")
      end

      it "defaults to String, and takes any other sequence sort" do
        expect(Re.Full.sort).to eq(sort)
        expect(Re.Full(int_seq).sort).to eq(int_seq_re)
      end

      it "constrains the solution" do
        expect([s.matches?(Re.Empty)]).to have_no_solution
        expect([s.matches?(Re.Full), s == "anything at all"]).to have_solution(s => %q{"anything at all"})
        expect([s.matches?(Re.AllChar), s == "a"]).to have_solution(s => %q{"a"})
        expect([s.matches?(Re.AllChar), s == "ab"]).to have_no_solution
      end

      it "are also on the sort" do
        expect(sort.empty).to be_same_as(Re.Empty)
        expect(sort.full).to be_same_as(Re.Full)
        expect(sort.all_char).to be_same_as(Re.AllChar)
      end
    end

    describe "#matches?" do
      it "is the same operation as StringExpr#matches?, the other way round" do
        expect(lower.matches?(s)).to be_same_as(s.matches?(lower))
      end

      it "converts its argument, since a sequence is never ambiguous here" do
        expect(lower.matches?("a").sexpr).to eq(%q{(str.in_re "a" (re.range "a" "z"))})
      end
    end

    describe "#seq_sort" do
      it "is what the regex ranges over" do
        expect(lower.seq_sort).to eq(StringSort.new)
        expect(Re.Of(xs).seq_sort).to eq(int_seq)
      end
    end

    describe "coercion" do
      it "mixing basis sorts is an error" do
        expect { Re.Union(Re.Of("a"), Re.Of(xs)) }.to raise_error(Z3::Exception)
      end

      it "needs something to say which sort is meant" do
        expect { Re.Union([1], [2]) }.to raise_error(Z3::Exception)
        expect(Re.Union(Re.Of(xs), [1]).sort).to eq(int_seq_re)
      end
    end

    # It comes from Expr, but what Z3 does with it is worth pinning down: two regexes
    # are equal when they accept the same language, not when they're the same term
    describe "#==" do
      it "is language equivalence" do
        a = Re.Of("a")
        b = Re.Of("b")
        expect([a.star != a.star.star]).to have_no_solution
        expect([(a + b).star + a != a + (b + a).star]).to have_no_solution
        expect([Re.Of("a") != Re.Range("a", "a")]).to have_no_solution
      end

      it "and different languages are different" do
        expect([Re.Of("a").star == Re.Union("a", "b").star]).to have_no_solution
      end
    end

    describe "sequence regexes" do
      it "work the same way" do
        expect([xs.matches?(Re.Of([1, 2], int_seq) * (2..2))]).to have_solution(xs => "[1, 2, 1, 2]")
      end
    end
  end
end
