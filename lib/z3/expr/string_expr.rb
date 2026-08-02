module Z3
  # The Ruby side of this reads like Ruby's String - see SeqExpr for why the two
  # don't share a hierarchy even though Z3 models a String as a Seq(Char).
  #
  # Where Ruby and SMT-LIB disagree, Ruby wins: `#include?` rather than `contains?`,
  # `#sub` / `#gsub` rather than `replace` / `replace_all`, the receiver back in front
  # of `#start_with?`, and a negative index counted from the end.
  #
  # Where Ruby answers `nil` there's no conflict to resolve, because there's nothing to
  # answer. Every one of these is a subexpression - `s[i]` can appear as `s[i] + "!"`,
  # or under an `==`, or buried in a term a model hands back - so it has to denote a
  # String, and no String is `nil`. Those just return whatever Z3 returns, and the
  # method comments say what that is.
  class StringExpr < Expr
    public_class_method :new

    # `str.len` and `seq.len` are one Z3 operation, so SeqExpr#length is the same
    # call - shared through LowLevel, not through a superclass. Ruby String has both
    # #length and #size, so this has both too.
    def length
      IntSort.new.new(LowLevel.mk_seq_length(self))
    end

    def size
      length
    end

    def empty?
      length == 0
    end

    # Ruby String#+ is concatenation, and so is `str.++`. It deliberately doesn't go
    # through Expr.Add, which stays arithmetic only.
    def +(other)
      StringExpr.Concat(self, other)
    end

    # Ruby String#* repeats. Z3 has no repetition operator, so it's Ruby-side
    # concatenation, and the count has to be a Ruby Integer rather than an IntExpr.
    def *(count)
      raise Z3::Exception, "Can only repeat a String a non-negative Integer number of times" unless count.is_a?(Integer) and count >= 0
      return sort.from_const("") if count == 0
      StringExpr.Concat(*([self] * count))
    end

    # Ruby String#[]. `s[i]` is a one character String (`str.at`), `s[i, len]` and
    # `s[range]` are substrings (`str.substr`), and a negative index counts from the
    # end just like Ruby's. Out of range this is whatever Z3 says, which is `""` -
    # the result is a String-sorted subexpression, so `nil` isn't one of its options.
    def [](index, len=nil)
      if len
        substr(Expr.normalize_index(index, length), len)
      elsif index.is_a?(Range)
        substr(*Expr.offset_and_length(index, length))
      else
        sort.new(LowLevel.mk_seq_at(self, IntSort.new.cast(Expr.normalize_index(index, length))))
      end
    end

    # Ruby String#slice is String#[]
    alias_method :slice, :[]

    # Ruby String#include? - a substring, not a character
    def include?(substring)
      BoolSort.new.new(LowLevel.mk_seq_contains(self, sort.cast(substring)))
    end

    # Z3's `str.prefixof` takes the prefix first and the string second, the opposite
    # way round from Ruby's String#start_with?. Like Ruby's, this takes any number of
    # candidates and holds if any of them matches - and none at all is false.
    def start_with?(*prefixes)
      return BoolSort.new.False if prefixes.empty?
      matches = prefixes.map { |prefix|
        BoolSort.new.new(LowLevel.mk_seq_prefix(sort.cast(prefix), self))
      }
      # `Or` of one thing prints as `or(...)`, and every caller is more likely to pass one
      matches.size == 1 ? matches[0] : BoolExpr.Or(*matches)
    end

    # Ruby String#end_with?, `str.suffixof` with the arguments the other way round
    def end_with?(*suffixes)
      return BoolSort.new.False if suffixes.empty?
      matches = suffixes.map { |suffix|
        BoolSort.new.new(LowLevel.mk_seq_suffix(sort.cast(suffix), self))
      }
      # `Or` of one thing prints as `or(...)`, and every caller is more likely to pass one
      matches.size == 1 ? matches[0] : BoolExpr.Or(*matches)
    end

    # Ruby String#index. This denotes an Int, so there's no `nil` available for it to be
    # when there's no match - `str.indexof` answers -1, and that's what comes back
    def index(substring, offset=0)
      IntSort.new.new(LowLevel.mk_seq_index(self, sort.cast(substring), IntSort.new.cast(offset)))
    end

    # Ruby String#rindex. Z3's `seq.last_indexof` takes no offset, so neither does this.
    def rindex(substring)
      IntSort.new.new(LowLevel.mk_seq_last_index(self, sort.cast(substring)))
    end

    # Ruby String#sub and #gsub, split the same way: `str.replace` replaces the first
    # occurrence, `str.replace_all` every one. The pattern is a string, not a Regexp.
    def sub(pattern, replacement)
      sort.new(LowLevel.mk_seq_replace(self, sort.cast(pattern), sort.cast(replacement)))
    end

    def gsub(pattern, replacement)
      sort.new(LowLevel.mk_seq_replace_all(self, sort.cast(pattern), sort.cast(replacement)))
    end

    # Ruby String#to_i, so this is the symbolic `str.to_int` - not IntExpr#to_i, which
    # goes the other way and gives a Ruby Integer. #to_str is the one that gives a Ruby
    # object back.
    #
    # `str.to_int` isn't quite Ruby's String#to_i, though: it takes a non-negative run
    # of digits and answers -1 for anything else, where Ruby skips leading whitespace,
    # takes a sign, parses a digit prefix (`"12ab".to_i` is 12) and answers 0 on
    # failure. A prefix scan needs recursive functions the gem doesn't have, and
    # clamping the -1 to 0 would buy `"abc".to_i == 0` and nothing else while costing
    # the one way to write "this isn't a number" - so this returns what Z3 returns.
    def to_i
      IntSort.new.new(LowLevel.mk_str_to_int(self))
    end

    # A Ruby String out of a string value, the way IntExpr#to_i gives a Ruby Integer
    def to_str
      obj = string_value? ? self : simplify
      raise Z3::Exception, "Can't convert expression #{self} to String" unless obj.string_value?
      LowLevel.get_string(obj)
    end

    # String values are indexed decls - `(_ String "abc")` - not numerals, so
    # `ast_kind` says `:app` for them just as it does for `s + "!"`
    def string_value?
      return false unless ast_kind == :app
      decl = func_decl
      decl.arity == 0 and decl.num_parameters == 1 and decl.parameter_kind(0) == :zstring
    end

    # `str.<` / `str.<=` are lexicographic, and have nothing to do with `==`
    def <(other)
      StringExpr.Lt(self, other)
    end

    def <=(other)
      StringExpr.Le(self, other)
    end

    def >(other)
      StringExpr.Lt(other, self)
    end

    def >=(other)
      StringExpr.Le(other, self)
    end

    private

    # `str.substr`, with the offset already counted from the end if it was negative.
    # `s[offset, len]` is the Ruby spelling, so that's the only one exposed.
    def substr(offset, len)
      sort.new(LowLevel.mk_seq_extract(self, IntSort.new.cast(offset), IntSort.new.cast(len)))
    end

    class << self
      def coerce_to_string_sort(*args)
        args = coerce_to_same_sort(*args)
        raise Z3::Exception, "String value expected" unless args[0].is_a?(StringExpr)
        args
      end

      def Concat(*args)
        raise Z3::Exception, "Concat requires at least one argument" if args.empty?
        args = coerce_to_string_sort(*args)
        # Z3 rejects a concatenation of fewer than two strings
        return args[0] if args.size == 1
        args[0].sort.new(LowLevel.mk_seq_concat(args))
      end

      def Lt(a, b)
        a, b = coerce_to_string_sort(a, b)
        BoolSort.new.new(LowLevel.mk_str_lt(a, b))
      end

      def Le(a, b)
        a, b = coerce_to_string_sort(a, b)
        BoolSort.new.new(LowLevel.mk_str_le(a, b))
      end
    end
  end
end
