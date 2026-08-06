module Z3
  describe StringExpr do
    let(:sort) { StringSort.new }
    let(:s) { sort.var("s") }
    let(:t) { sort.var("t") }
    let(:x) { Z3.Int("x") }

    describe "#length" do
      it "is an IntExpr" do
        expect(s.length).to be_a(IntExpr)
        expect(s.length.sort).to eq(IntSort.new)
      end

      # Z3 calls it `str.len` for strings and `seq.len` for other sequences,
      # even though it's one operation
      it "sexpr" do
        expect(s.length.sexpr).to eq("(str.len s)")
        expect(sort.from_const("hello").length.sexpr).to eq(%q{(str.len "hello")})
      end

      it "prints as a Ruby method call" do
        expect(s.length).to stringify("s.size")
        expect(sort.from_const("hello").length).to stringify(%q{"hello".size})
      end

      it "#size is the same thing" do
        expect(s.size).to be_same_as(s.length)
      end

      it "evaluates in a model" do
        solver = Solver.new
        solver.assert s == "héllo"
        expect(solver).to be_satisfiable
        expect(solver.model.model_eval(s.length).to_s).to eq("5")
      end

      it "constrains the solution" do
        expect([s.length == 5, s == "hello"]).to have_solution(s => "hello")
        expect([s.length == 5, s == "abc"]).to have_no_solution
      end

      # It's an ordinary IntExpr, so all of ArithExpr works on it
      it "does arithmetic" do
        expect([s.length + 1 == 4, s == "abc"]).to have_solution(s => "abc")
        expect([s.length >= 2, s.length <= 2, s == "ab"]).to have_solution(s => "ab")
      end

      it "is zero for the empty string" do
        solver = Solver.new
        solver.assert s == ""
        expect(solver).to be_satisfiable
        expect(solver.model.model_eval(s.length).to_s).to eq("0")
      end
    end

    describe "#empty?" do
      it "sexpr" do
        expect(s.empty?.sexpr).to eq("(= (str.len s) 0)")
      end

      it "constrains the solution" do
        expect([s.empty?]).to have_solution(s => "")
        expect([s.empty?, s.length == 1]).to have_no_solution
      end
    end

    describe "#value" do
      it "gives a Ruby String back, the way IntExpr#to_i gives a Ruby Integer" do
        expect(sort.from_const("hello").value).to eq("hello")
        expect(sort.from_const("").value).to eq("")
        expect(sort.from_const("héllo 中😀").value).to eq("héllo 中😀")
      end

      it "simplifies first, like IntExpr#to_i does" do
        expect((sort.from_const("ab") + "cd").value).to eq("abcd")
      end

      it "raises exception when there's nothing to convert" do
        expect { s.value }.to raise_error(Z3::Exception)
        expect { (s + "!").value }.to raise_error(Z3::Exception)
      end

      it "reads a model" do
        solver = Solver.new
        solver.assert s + "!" == "hello!"
        expect(solver).to be_satisfiable
        expect(solver.model[s].value).to eq("hello")
      end
    end

    describe "#+" do
      it "is concatenation, not Expr.Add" do
        expect((s + "!").sexpr).to eq(%q{(str.++ s "!")})
        expect(s + "!").to be_a(StringExpr)
      end

      it "autoconverts Ruby Strings on either side" do
        expect(("pre" + s).sexpr).to eq(%q{(str.++ "pre" s)})
      end

      it "prints as Ruby" do
        expect(s + "!").to stringify(%q{s + "!"})
      end

      it "constrains the solution" do
        expect(["he" + s + "!" == "hello!"]).to have_solution(s => "llo")
      end
    end

    describe "#*" do
      it "repeats, like Ruby String#*" do
        expect((s * 3).sexpr).to eq("(str.++ s s s)")
        expect(s * 1).to be_same_as(s)
        expect((s * 0).value).to eq("")
        expect([s == "ab", s * 3 == "ababab"]).to have_solution(s => "ab")
      end

      # Z3 has no repetition operator, so the count can't be symbolic
      it "raises exception on anything but a non-negative Integer" do
        expect { s * -1 }.to raise_error(Z3::Exception)
        expect { s * IntSort.new.var("n") }.to raise_error(Z3::Exception)
        expect { s * "x" }.to raise_error(Z3::Exception)
      end
    end

    describe "#[]" do
      # `str.at` for a single index, `str.substr` for a range or a length
      it "sexpr" do
        expect(s[2].sexpr).to eq("(str.at s 2)")
        expect(s[2, 3].sexpr).to eq("(str.substr s 2 3)")
        expect(s[2..4].sexpr).to eq("(str.substr s 2 3)")
        expect(s[2...4].sexpr).to eq("(str.substr s 2 2)")
      end

      it "is a String either way" do
        expect(s[2]).to be_a(StringExpr)
        expect(s[2, 3]).to be_a(StringExpr)
      end

      it "prints as Ruby" do
        expect(s[2]).to stringify("s[2]")
        expect(s[2, 3]).to stringify("s[2, 3]")
      end

      it "indexes" do
        expect([s == "hello", s[1] == "e"]).to have_solution(s => "hello")
        expect([s == "hello", s[1] == "x"]).to have_no_solution
      end

      it "takes substrings" do
        expect([s == "hello", s[1, 3] == "ell"]).to have_solution(s => "hello")
        expect([s == "hello", s[1..3] == "ell"]).to have_solution(s => "hello")
        expect([s == "hello", s[1...3] == "el"]).to have_solution(s => "hello")
      end

      # An open ended range runs to the end of the string, so it needs the length
      it "takes substrings with open ended ranges" do
        expect([s == "hello", s[2..] == "llo"]).to have_solution(s => "hello")
        expect([s == "hello", s[..2] == "hel"]).to have_solution(s => "hello")
      end

      # An index is an offset however it's spelled, so a literal -1 and an IntExpr
      # equal to -1 have to mean the same thing. Only the literal could ever be
      # recognized as negative, so neither counts from the end - `t` is what Z3
      # answers, rather than an answer proposed to it.
      it "means the same by a literal index and a symbolic one" do
        expect([s == "hello", x == -1, t == s[-1]]).to have_solution(t => "")
        expect([s == "hello", x == -1, t == s[x]]).to have_solution(t => "")
        expect([s == "hello", x == -1, t == s[-1, 2]]).to have_solution(t => "")
        expect([s == "hello", x == -1, t == s[x, 2]]).to have_solution(t => "")
        expect([s == "hello", x == -1, t == s[0..-1]]).to have_solution(t => "")
        expect([s == "hello", x == -1, t == s[0..x]]).to have_solution(t => "")
      end

      it "passes a negative index through as an offset" do
        expect(s[-1].sexpr).to eq("(str.at s (- 1))")
        expect(s[-2, 2].sexpr).to eq("(str.substr s (- 2) 2)")
      end

      # Counting from the end is spelled out, and then it works for a symbolic offset
      # too, which is the whole point of not emulating it
      it "counts from the end when told to" do
        expect([s == "hello", t == s[s.length - 1]]).to have_solution(t => "o")
        expect([s == "hello", x == 1, t == s[s.length - x]]).to have_solution(t => "o")
        expect([s == "hello", t == s[s.length - 2, 2]]).to have_solution(t => "lo")
      end

      # This denotes a String wherever it appears, so `nil` was never one of its
      # options - out of range is simply whatever Z3 says, and Z3 says ""
      it "is whatever Z3 says out of range, where Ruby is nil" do
        expect([s == "hello", s[10] == ""]).to have_solution(s => "hello")
        expect([s == "hello", s[-10] == ""]).to have_solution(s => "hello")
        expect([s == "hello", s[3, 100] == "lo"]).to have_solution(s => "hello")
      end

      it "#slice is #[], like Ruby's" do
        expect(s.slice(2)).to be_same_as(s[2])
        expect(s.slice(1, 2)).to be_same_as(s[1, 2])
        expect(s.slice(1..2)).to be_same_as(s[1..2])
      end

      it "takes symbolic indices" do
        i = IntSort.new.var("i")
        expect([s == "hello", s[i] == "l", i == 2]).to have_solution(s => "hello")
        expect([s == "hello", s[i, 2] == "lo", i == 3]).to have_solution(s => "hello")
      end

      # Both ends of a Range can be symbolic too, open ends included - it's all Ruby
      # arithmetic on top of `str.substr`, and none of it looks at the index
      it "takes symbolic ranges" do
        i = IntSort.new.var("i")
        j = IntSort.new.var("j")
        expect([s == "hello", i == 1, j == 3, t == s[i..j]]).to have_solution(t => "ell")
        expect([s == "hello", i == 1, j == 3, t == s[i...j]]).to have_solution(t => "el")
        expect([s == "hello", i == 2, t == s[i..]]).to have_solution(t => "llo")
        expect([s == "hello", i == 2, t == s[..i]]).to have_solution(t => "hel")
        expect([s == "hello", i == 2, t == s[i..3]]).to have_solution(t => "ll")
        expect([s == "hello", i == 3, t == s[1..i]]).to have_solution(t => "ell")
      end

      it "means the same by a literal range end and a symbolic one" do
        expect(s[..x]).to be_same_as(s[0..x])
        [2, 0, -1, 10].each do |v|
          expect([s == "hello", x == v, s[x..] == s[v..]]).to have_solution(s => "hello")
          expect([s == "hello", x == v, s[..x] == s[..v]]).to have_solution(s => "hello")
          expect([s == "hello", x == v, s[x..] != s[v..]]).to have_no_solution
          expect([s == "hello", x == v, s[..x] != s[..v]]).to have_no_solution
        end
      end

      it "builds the range arithmetic without an extra zero" do
        expect(s[..x].sexpr).to eq("(str.substr s 0 (+ x 1))")
        expect(s[x..].sexpr).to eq("(str.substr s x (- (str.len s) x))")
        expect(s[x..2].sexpr).to eq("(str.substr s x (+ (- 2 x) 1))")
      end
    end

    describe "#include?" do
      it "sexpr" do
        expect(s.include?("ll").sexpr).to eq(%q{(str.contains s "ll")})
      end

      it "is a BoolExpr" do
        expect(s.include?("ll")).to be_a(BoolExpr)
      end

      it "prints as Ruby" do
        expect(s.include?("ll")).to stringify(%q{s.include?("ll")})
      end

      it "constrains the solution" do
        expect([s == "hello", s.include?("ell")]).to have_solution(s => "hello")
        expect([s == "hello", s.include?("xyz")]).to have_no_solution
        expect([s == "hello", ~s.include?("ell")]).to have_no_solution
      end
    end

    describe "#start_with? and #end_with?" do
      # Z3 takes the prefix first and the string second, Ruby the other way round
      it "sexpr" do
        expect(s.start_with?("he").sexpr).to eq(%q{(str.prefixof "he" s)})
        expect(s.end_with?("lo").sexpr).to eq(%q{(str.suffixof "lo" s)})
      end

      it "prints as Ruby, with the receiver back in front" do
        expect(s.start_with?("he")).to stringify(%q{s.start_with?("he")})
        expect(s.end_with?("lo")).to stringify(%q{s.end_with?("lo")})
      end

      it "constrains the solution" do
        expect([s == "hello", s.start_with?("he")]).to have_solution(s => "hello")
        expect([s == "hello", s.start_with?("lo")]).to have_no_solution
        expect([s == "hello", s.end_with?("lo")]).to have_solution(s => "hello")
        expect([s == "hello", s.end_with?("he")]).to have_no_solution
      end

      # Ruby's take any number of candidates and are true if any matches
      it "takes multiple candidates" do
        expect([s == "hello", s.start_with?("xy", "he")]).to have_solution(s => "hello")
        expect([s == "hello", s.start_with?("xy", "zw")]).to have_no_solution
        expect([s == "hello", s.end_with?("xy", "lo")]).to have_solution(s => "hello")
      end

      it "is false with no candidates at all, like Ruby's" do
        expect([s.start_with?]).to have_no_solution
        expect([s.end_with?]).to have_no_solution
      end
    end

    describe "#index and #rindex" do
      it "sexpr" do
        expect(s.index("l").sexpr).to eq(%q{(str.indexof s "l" 0)})
        expect(s.index("l", 3).sexpr).to eq(%q{(str.indexof s "l" 3)})
        expect(s.rindex("l").sexpr).to eq(%q{(seq.last_indexof s "l")})
      end

      it "is an IntExpr" do
        expect(s.index("l")).to be_a(IntExpr)
        expect(s.rindex("l")).to be_a(IntExpr)
      end

      it "prints as Ruby" do
        expect(s.index("l")).to stringify(%q{s.index("l")})
        expect(s.rindex("l")).to stringify(%q{s.rindex("l")})
      end

      it "finds the first and the last occurrence" do
        expect([s == "hello", s.index("l") == 2]).to have_solution(s => "hello")
        expect([s == "hello", s.index("l", 3) == 3]).to have_solution(s => "hello")
        expect([s == "hello", s.rindex("l") == 3]).to have_solution(s => "hello")
      end

      # This denotes an Int, so there's no `nil` for it to be - Z3 answers -1
      it "is -1 with no match, not nil" do
        expect([s == "hello", s.index("z") == -1]).to have_solution(s => "hello")
      end
    end

    describe "#matches?" do
      it "sexpr" do
        expect(s.matches?(Re.Of("ab")).sexpr).to eq(%q{(str.in_re s (str.to_re "ab"))})
      end

      it "prints as Ruby" do
        expect(s.matches?(Re.Range("a", "z").star)).to stringify(%q{s.matches?(Re.Range("a", "z").star)})
      end

      it "matches the whole string, not a substring" do
        expect([s.matches?(Re.Range("a", "z").plus), s == "abc"]).to have_solution(s => "abc")
        expect([s.matches?(Re.Range("a", "z").plus), s == "ab1"]).to have_no_solution
        # Ruby's String#match? would search - that's spelled out here
        expect([s.matches?(Re.Full + Re.Of("b") + Re.Full), s == "ab1"]).to have_solution(s => "ab1")
      end

      # Everywhere else a Ruby String converts to the regex matching exactly it, but
      # here that would look like Ruby's unanchored String#match? and mean the opposite
      it "does not convert its argument" do
        expect { s.matches?("ab") }.to raise_error(Z3::Exception)
        expect { s.matches?(t) }.to raise_error(Z3::Exception)
      end

      it "rejects a Re over the wrong sort" do
        expect { s.matches?(Re.Of([1], SeqSort.new(IntSort.new))) }.to raise_error(Z3::Exception)
      end
    end

    describe "#sub and #gsub" do
      # The same first-one versus every-one split Ruby's have
      it "sexpr" do
        expect(s.sub("a", "b").sexpr).to eq(%q{(str.replace s "a" "b")})
        expect(s.gsub("a", "b").sexpr).to eq(%q{(str.replace_all s "a" "b")})
      end

      it "prints as Ruby" do
        expect(s.sub("a", "b")).to stringify(%q{s.sub("a", "b")})
        expect(s.gsub("a", "b")).to stringify(%q{s.gsub("a", "b")})
      end

      it "replaces the first occurrence, or all of them" do
        expect([s == "banana", s.sub("a", "!") == "b!nana"]).to have_solution(s => "banana")
        expect([s == "banana", s.gsub("a", "!") == "b!n!n!"]).to have_solution(s => "banana")
      end

      # `str.replace_re` / `str.replace_re_all`, and unanchored like Ruby's are.
      # Z3 4.16 builds these terms but neither solves nor simplifies them, so there's
      # nothing to assert past the term itself.
      it "takes a Re pattern, like Ruby's do" do
        expect(s.sub(Re.Range("a", "z"), "!").sexpr).to eq(%q{(str.replace_re s (re.range "a" "z") "!")})
        expect(s.gsub(Re.Range("a", "z"), "!").sexpr).to eq(%q{(str.replace_re_all s (re.range "a" "z") "!")})
        expect(s.sub(Re.Range("a", "z"), "!")).to be_a(StringExpr)
        expect(s.gsub(Re.Range("a", "z"), "!")).to be_a(StringExpr)
      end

      it "rejects a Re over the wrong sort" do
        expect { s.sub(Re.Of([1], SeqSort.new(IntSort.new)), "!") }.to raise_error(Z3::Exception)
      end

      # The classic path traversal bug - one pass of the sanitizer isn't enough
      it "finds an input that defeats a one pass sanitizer" do
        solver = Solver.new
        solver.assert ("/srv/" + s.sub("../", "")).include?("../")
        solver.assert s.length <= 8
        expect(solver).to be_satisfiable
        value = solver.model[s].value
        expect(value.sub("../", "")).to include("../")
      end
    end

    describe "#to_i" do
      # Ruby's String#to_i, so symbolic - unlike IntExpr#to_i, which gives a Ruby Integer
      it "sexpr" do
        expect(s.to_i.sexpr).to eq("(str.to_int s)")
        expect(s.to_i).to be_a(IntExpr)
      end

      it "prints as Ruby" do
        expect(s.to_i).to stringify("s.to_i")
      end

      it "parses digits" do
        expect([s == "42", s.to_i == 42]).to have_solution(s => "42")
        expect([s.to_i == 42, s.length == 2]).to have_solution(s => "42")
      end

      # Ruby answers 0 for "abc" and 12 for "12ab"; Z3 answers -1 for both
      it "is -1 for anything that isn't all digits" do
        expect([s == "abc", s.to_i == -1]).to have_solution(s => "abc")
        expect([s == "12ab", s.to_i == -1]).to have_solution(s => "12ab")
      end
    end

    # StringSort#from_code backwards
    describe "#to_code" do
      it "is the code point of a one character string" do
        expect(s.to_code).to be_a(IntExpr)
        expect([s == "A", s.to_code == 65]).to have_solution(s => "A")
        expect([s == "中", s.to_code == 0x4e2d]).to have_solution(s => "中")
      end

      # Same -1 convention as #to_i uses for a string that isn't a number
      it "is -1 for a string of any other length" do
        expect([s == "ab", s.to_code == -1]).to have_solution(s => "ab")
        expect([s == "", s.to_code == -1]).to have_solution(s => "")
      end
    end

    describe "comparisons" do
      # `str.<` / `str.<=` are lexicographic, and unrelated to `==`
      it "sexpr" do
        expect((s < "b").sexpr).to eq(%q{(str.< s "b")})
        expect((s <= "b").sexpr).to eq(%q{(str.<= s "b")})
        expect((s > "b").sexpr).to eq(%q{(str.< "b" s)})
        expect((s >= "b").sexpr).to eq(%q{(str.<= "b" s)})
      end

      it "works with a Ruby String on the left too" do
        expect(("b" < s).sexpr).to eq(%q{(str.< "b" s)})
        expect(("b" <= s).sexpr).to eq(%q{(str.<= "b" s)})
        expect(("b" > s).sexpr).to eq(%q{(str.< s "b")})
        expect(("b" >= s).sexpr).to eq(%q{(str.<= s "b")})
      end

      it "prints as Ruby" do
        expect(s < "b").to stringify(%q{s < "b"})
        expect(s <= "b").to stringify(%q{s <= "b"})
      end

      it "orders lexicographically, not by length" do
        expect([s == "abc", s < "abd"]).to have_solution(s => "abc")
        expect([s == "abc", s < "ab"]).to have_no_solution
        expect([s == "abc", s <= "abc"]).to have_solution(s => "abc")
        expect([s == "abc", s < "abc"]).to have_no_solution
      end

      it "constrains the solution" do
        expect([s > "apple", s < "applf", s.length == 5]).to have_no_solution
        solver = Solver.new
        solver.assert s > "apple"
        solver.assert s < "apply"
        solver.assert s.length == 5
        expect(solver).to be_satisfiable
        expect(solver.model[s].value).to be_between("apple", "apply").exclusive
      end
    end

    describe "raises exception on sort mismatch" do
      # Casting straight to StringSort is ours, coercing two sorts to their maximum is
      # Expr's - and Expr's ArgumentError for incomparable sorts is what every other
      # Expr raises too
      it "for operations taking a string" do
        expect { s.include?(5) }.to raise_error(Z3::Exception)
        expect { s.sub(5, "a") }.to raise_error(Z3::Exception)
        expect { s + 5 }.to raise_error(ArgumentError)
        expect { s < 5 }.to raise_error(ArgumentError)
        expect { StringExpr.Concat(s, IntSort.new.var("i")) }.to raise_error(ArgumentError)
      end
    end

    # A String is a Seq(Char) to Z3, so it gets the same map and fold operations,
    # with the block taking a Char
    describe "#map and #inject" do
      it "map to Char gives a String back, and to anything else a Seq" do
        expect(s.map { |c| c }.sort).to eq(StringSort.new)
        expect(s.map { |c| c.to_i }.sort).to eq(SeqSort.new(IntSort.new))
        expect(s.inject(0) { |a, _c| a + 1 }.sort).to eq(IntSort.new)
      end

      it "prints as Ruby, the same as a Seq does" do
        expect(s.map(Z3.Lambda(CharSort.new.var("c"), CharSort.new.var("c"))))
          .to stringify("s.map((lambda ((c Unicode)) c))")
      end

      it "constrains correctly" do
        solver = Solver.new
        solver.assert s == "abc"
        solver.assert(s.map { |c| c } == sort.from_const("abc"))
        expect(solver).to be_satisfiable

        solver = Solver.new
        solver.assert s == "abc"
        solver.assert(s.map { |c| c } == sort.from_const("xyz"))
        expect(solver).to_not be_satisfiable
      end

      # The catch worth pinning down, because it's the whole difference from Seq:
      # Z3 gets the constraint semantics right but never reduces the term, so there
      # is nothing to read back. Not through the model, not through #simplify, and
      # not by equating it to a free variable either.
      it "is never evaluated, unlike the same map over a Seq" do
        solver = Solver.new
        solver.assert s == "abc"
        counted = s.inject(0) { |a, _c| a + 1 }
        expect(solver).to be_satisfiable
        expect { solver.model[counted].value }.to raise_error(Z3::Exception)
        expect { counted.simplify.value }.to raise_error(Z3::Exception)

        # ...where a Seq(Int) folds down to a number
        seq = SeqSort.new(IntSort.new)
        xs = seq.var("xs")
        solver = Solver.new
        solver.assert xs == seq.from_const([1, 2, 3])
        expect(solver).to be_satisfiable
        expect(solver.model[xs.inject(0) { |a, _x| a + 1 }].value).to eq(3)
      end
    end

    describe ".Concat" do
      it "concatenates any number of strings" do
        expect(StringExpr.Concat(s, "a", "b").sexpr).to eq(%q{(str.++ s "a" "b")})
        # Z3 rejects a concatenation of fewer than two strings
        expect(StringExpr.Concat(s)).to be_same_as(s)
        expect { StringExpr.Concat }.to raise_error(Z3::Exception)
      end
    end
  end
end
