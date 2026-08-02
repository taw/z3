module Z3
  describe StringExpr do
    let(:sort) { StringSort.new }
    let(:s) { sort.var("s") }

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
        expect([s.length == 5, s == "hello"]).to have_solution(s => %q{"hello"})
        expect([s.length == 5, s == "abc"]).to have_no_solution
      end

      # It's an ordinary IntExpr, so all of ArithExpr works on it
      it "does arithmetic" do
        expect([s.length + 1 == 4, s == "abc"]).to have_solution(s => %q{"abc"})
        expect([s.length >= 2, s.length <= 2, s == "ab"]).to have_solution(s => %q{"ab"})
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
        expect([s.empty?]).to have_solution(s => %q{""})
        expect([s.empty?, s.length == 1]).to have_no_solution
      end
    end

    describe "#to_str" do
      it "gives a Ruby String back, the way IntExpr#to_i gives a Ruby Integer" do
        expect(sort.from_const("hello").to_str).to eq("hello")
        expect(sort.from_const("").to_str).to eq("")
        expect(sort.from_const("héllo 中😀").to_str).to eq("héllo 中😀")
      end

      it "simplifies first, like IntExpr#to_i does" do
        expect((sort.from_const("ab") + "cd").to_str).to eq("abcd")
      end

      it "raises exception when there's nothing to convert" do
        expect { s.to_str }.to raise_error(Z3::Exception)
        expect { (s + "!").to_str }.to raise_error(Z3::Exception)
      end

      it "reads a model" do
        solver = Solver.new
        solver.assert s + "!" == "hello!"
        expect(solver).to be_satisfiable
        expect(solver.model[s].to_str).to eq("hello")
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
        expect(["he" + s + "!" == "hello!"]).to have_solution(s => %q{"llo"})
      end
    end

    describe "#*" do
      it "repeats, like Ruby String#*" do
        expect((s * 3).sexpr).to eq("(str.++ s s s)")
        expect(s * 1).to be_same_as(s)
        expect((s * 0).to_str).to eq("")
        expect([s == "ab", s * 3 == "ababab"]).to have_solution(s => %q{"ab"})
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
        expect([s == "hello", s[1] == "e"]).to have_solution(s => %q{"hello"})
        expect([s == "hello", s[1] == "x"]).to have_no_solution
      end

      it "takes substrings" do
        expect([s == "hello", s[1, 3] == "ell"]).to have_solution(s => %q{"hello"})
        expect([s == "hello", s[1..3] == "ell"]).to have_solution(s => %q{"hello"})
        expect([s == "hello", s[1...3] == "el"]).to have_solution(s => %q{"hello"})
      end

      # An open ended range runs to the end of the string, so it needs the length
      it "takes substrings with open ended ranges" do
        expect([s == "hello", s[2..] == "llo"]).to have_solution(s => %q{"hello"})
        expect([s == "hello", s[..2] == "hel"]).to have_solution(s => %q{"hello"})
      end

      # A Ruby Integer can be recognized as negative, so it counts from the end the
      # way Ruby's does. Every one of these is checked against what Ruby answers.
      it "counts a negative index from the end, like Ruby" do
        solver = Solver.new
        solver.assert s == "hello"
        expect(solver).to be_satisfiable
        model = solver.model
        indices = [-1, -5, -10, 0, 2, 10]
        indices.each do |i|
          expect(model.model_eval(s[i]).to_str).to eq("hello"[i].to_s), "s[#{i}]"
        end
        [[-2, 2], [-5, 3], [1, 2], [-10, 2]].each do |offset, len|
          expect(model.model_eval(s[offset, len]).to_str).to eq("hello"[offset, len].to_s), "s[#{offset}, #{len}]"
        end
        [0..-1, 1..-2, -3..-1, -3...-1, -3.., ..-2, 2.., ..2].each do |range|
          expect(model.model_eval(s[range]).to_str).to eq("hello"[range].to_s), "s[#{range}]"
        end
      end

      it "is negative when it counts from the end" do
        expect(s[-1].sexpr).to eq("(str.at s (- (str.len s) 1))")
        expect(s[-2, 2].sexpr).to eq("(str.substr s (- (str.len s) 2) 2)")
      end

      # This denotes a String wherever it appears, so `nil` was never one of its
      # options - out of range is simply whatever Z3 says, and Z3 says ""
      it "is whatever Z3 says out of range, where Ruby is nil" do
        expect([s == "hello", s[10] == ""]).to have_solution(s => %q{"hello"})
        expect([s == "hello", s[-10] == ""]).to have_solution(s => %q{"hello"})
        expect([s == "hello", s[3, 100] == "lo"]).to have_solution(s => %q{"hello"})
      end

      # Nothing can be told about a symbolic index at build time, so it isn't counted
      # backwards - it's just out of range, and therefore ""
      it "can't count a symbolic index from the end" do
        i = IntSort.new.var("i")
        expect([s == "hello", i == -1, s[i] == ""]).to have_solution(s => %q{"hello"})
      end

      it "#slice is #[], like Ruby's" do
        expect(s.slice(2)).to be_same_as(s[2])
        expect(s.slice(1, 2)).to be_same_as(s[1, 2])
        expect(s.slice(1..2)).to be_same_as(s[1..2])
      end

      it "takes symbolic indices" do
        i = IntSort.new.var("i")
        expect([s == "hello", s[i] == "l", i == 2]).to have_solution(s => %q{"hello"})
        expect([s == "hello", s[i, 2] == "lo", i == 3]).to have_solution(s => %q{"hello"})
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
        expect([s == "hello", s.include?("ell")]).to have_solution(s => %q{"hello"})
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
        expect([s == "hello", s.start_with?("he")]).to have_solution(s => %q{"hello"})
        expect([s == "hello", s.start_with?("lo")]).to have_no_solution
        expect([s == "hello", s.end_with?("lo")]).to have_solution(s => %q{"hello"})
        expect([s == "hello", s.end_with?("he")]).to have_no_solution
      end

      # Ruby's take any number of candidates and are true if any matches
      it "takes multiple candidates" do
        expect([s == "hello", s.start_with?("xy", "he")]).to have_solution(s => %q{"hello"})
        expect([s == "hello", s.start_with?("xy", "zw")]).to have_no_solution
        expect([s == "hello", s.end_with?("xy", "lo")]).to have_solution(s => %q{"hello"})
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
        expect([s == "hello", s.index("l") == 2]).to have_solution(s => %q{"hello"})
        expect([s == "hello", s.index("l", 3) == 3]).to have_solution(s => %q{"hello"})
        expect([s == "hello", s.rindex("l") == 3]).to have_solution(s => %q{"hello"})
      end

      # This denotes an Int, so there's no `nil` for it to be - Z3 answers -1
      it "is -1 with no match, not nil" do
        expect([s == "hello", s.index("z") == -1]).to have_solution(s => %q{"hello"})
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
        expect([s == "banana", s.sub("a", "!") == "b!nana"]).to have_solution(s => %q{"banana"})
        expect([s == "banana", s.gsub("a", "!") == "b!n!n!"]).to have_solution(s => %q{"banana"})
      end

      # The classic path traversal bug - one pass of the sanitizer isn't enough
      it "finds an input that defeats a one pass sanitizer" do
        solver = Solver.new
        solver.assert ("/srv/" + s.sub("../", "")).include?("../")
        solver.assert s.length <= 8
        expect(solver).to be_satisfiable
        value = solver.model[s].to_str
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
        expect([s == "42", s.to_i == 42]).to have_solution(s => %q{"42"})
        expect([s.to_i == 42, s.length == 2]).to have_solution(s => %q{"42"})
      end

      # Ruby answers 0 for "abc" and 12 for "12ab"; Z3 answers -1 for both
      it "is -1 for anything that isn't all digits" do
        expect([s == "abc", s.to_i == -1]).to have_solution(s => %q{"abc"})
        expect([s == "12ab", s.to_i == -1]).to have_solution(s => %q{"12ab"})
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
        expect([s == "abc", s < "abd"]).to have_solution(s => %q{"abc"})
        expect([s == "abc", s < "ab"]).to have_no_solution
        expect([s == "abc", s <= "abc"]).to have_solution(s => %q{"abc"})
        expect([s == "abc", s < "abc"]).to have_no_solution
      end

      it "constrains the solution" do
        expect([s > "apple", s < "applf", s.length == 5]).to have_no_solution
        solver = Solver.new
        solver.assert s > "apple"
        solver.assert s < "apply"
        solver.assert s.length == 5
        expect(solver).to be_satisfiable
        expect(solver.model[s].to_str).to be_between("apple", "apply").exclusive
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
