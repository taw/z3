module Z3
  # A regular expression over some sequence sort - `Re(String)` for regexes over
  # Strings, `Re(Seq(Int))` for regexes over sequences of Ints.
  #
  # These are deliberately *not* Ruby Regexps, and nothing here converts between the
  # two in either direction. Ruby's regexes match unanchored, backtrack, and have
  # backreferences and lookaround; Z3's denote regular languages, match the whole
  # sequence, and are closed under intersection and complement. Compiling one into
  # the other would quietly change what a pattern means, so a Z3 regex is built out
  # of the combinators here - or out of a String or a Seq, which `seq.to_re` turns
  # into the regex matching exactly that one value and nothing else.
  #
  # That last conversion is what makes `Z3::Re.Union("cat", "dog")` work: anywhere a
  # regex is expected, a Ruby String, a Ruby Array, a StringExpr or a SeqExpr means
  # "the regex matching exactly this". The one place it deliberately doesn't happen
  # is #matches?, because that's where Ruby's reading and Z3's differ.
  #
  # `==` comes from Expr and needs no help here, but it's worth knowing what it means:
  # Z3 decides it as *language equivalence*, not as sameness of terms, so
  # `solver.prove! (a + b).star + a == a + (b + a).star` comes back proven. That's the
  # thing a backtracking regex engine can't do at all.
  class ReExpr < Expr
    public_class_method :new

    def seq_sort
      sort.seq_sort
    end

    # `re.*`, `re.+`, `re.opt`. Ruby has no operators for these - Ruby regexes spell
    # them inside the pattern - so they keep their SMT-LIB names.
    def star
      sort.new(LowLevel.mk_re_star(self))
    end

    def plus
      sort.new(LowLevel.mk_re_plus(self))
    end

    def option
      sort.new(LowLevel.mk_re_option(self))
    end

    # `+` is concatenation, the way it is for StringExpr and SeqExpr
    def +(other)
      ReExpr.Concat(self, other)
    end

    # A regex denotes a set of sequences, so the set operators are the ones that read
    # right: `|` union, `&` intersection, `-` difference, `~` complement. `|` and `&`
    # are also what Ruby's own Regexp alternation looks closest to.
    def |(other)
      ReExpr.Union(self, other)
    end

    def &(other)
      ReExpr.Intersect(self, other)
    end

    def -(other)
      ReExpr.Diff(self, other)
    end

    def ~
      sort.new(LowLevel.mk_re_complement(self))
    end

    # Repetition, spelled the way StringExpr#* spells it: `re * 3` is three copies
    # (`re.^`), and `re * (2..5)` is between two and five (`re.loop`). An endless
    # Range is an open upper bound, so `re * (2..)` is `re * 2 + re.star`.
    #
    # Both counts have to be Ruby Integers - Z3 takes them as decl parameters rather
    # than as arguments, so there's no symbolic form of either.
    def *(count)
      case count
      when Integer
        ReExpr.Power(self, count)
      when ::Range
        raise Z3::Exception, "Can only repeat a Re a Range of non-negative Integers" if count.begin and !count.begin.is_a?(Integer)
        ReExpr.Loop(self, count.begin || 0, ReExpr.range_end(count))
      else
        raise Z3::Exception, "Can only repeat a Re an Integer or a Range of Integers number of times"
      end
    end

    # `str.in_re` from the regex's side. Z3 matches the whole sequence, and this is
    # the one place that isn't Ruby's reading of the same word - Ruby's Regexp#match?
    # searches for the pattern anywhere in the string. Searching is spelled
    # `Z3::Re.Full + re + Z3::Re.Full`, which is why the argument here is never
    # silently converted: a bare String would look like Ruby's unanchored `match?`
    # and mean something else.
    def matches?(seq)
      BoolSort.new.new(LowLevel.mk_seq_in_re(seq_sort.cast(seq), self))
    end

    class << self
      # The regex sort a value belongs to. A ReExpr says so directly; a String or a
      # Seq says it through the sequence it is. A Ruby Array doesn't say anything -
      # `[]` could be a sequence of any element sort - and neither does anything else.
      def re_sort_for(value)
        case value
        when ReExpr
          value.sort
        when StringExpr, SeqExpr
          ReSort.new(value.sort)
        when ::String
          ReSort.new(StringSort.new)
        end
      end

      # Expr.coerce_to_same_sort can't do this job: it compares sorts, and a ReSort
      # and the SeqSort underneath it are unordered, so `max` on the pair raises
      # rather than picking the regex sort. Here the regex sort always wins, because
      # every argument to a regex operation is a regex.
      def coerce_to_same_re_sort(*args)
        raise Z3::Exception, "Re operations require at least one argument" if args.empty?
        sorts = args.map { |a| re_sort_for(a) }.compact.uniq
        if sorts.empty?
          raise Z3::Exception, "Can't tell which Re sort these belong to - pass a Re value, or say `ReSort.new(sort).cast(...)'"
        end
        raise Z3::Exception, "Re values with the same basis sort expected" unless sorts.size == 1
        args.map { |a| sorts[0].cast(a) }
      end

      # StringExpr#matches? and SeqExpr#matches? are the one place a value is *not*
      # silently turned into a regex - see ReExpr#matches? for why - so this checks
      # instead of casting.
      def expect_re_over(re, seq_sort)
        unless re.is_a?(ReExpr)
          raise Z3::Exception, "Expected a Re value, got #{re.class} - `Z3::Re.Of(x)' is the regex matching exactly `x', and `Z3::Re.Full + re + Z3::Re.Full' is what Ruby's unanchored match means"
        end
        raise Z3::Exception, "Can't match #{seq_sort} against #{re.sort}" unless re.seq_sort == seq_sort
        re
      end

      # The regex matching exactly one sequence - `seq.to_re`, and the only way a
      # value ever becomes a regex.
      #
      # A Ruby Array doesn't say what it's a sequence of, so that's the one case
      # which needs the sort spelled out: `Re.Of([1, 2], SeqSort.new(IntSort.new))`.
      def Of(value, seq_sort=nil)
        return ReSort.new(seq_sort).cast(value) if seq_sort
        coerce_to_same_re_sort(value)[0]
      end

      # `re.range`, from one character to another. Its arguments are one element
      # sequences rather than regexes, so they coerce as Strings/Seqs do.
      def Range(from, to)
        from, to = Expr.coerce_to_same_sort(from, to)
        unless from.is_a?(StringExpr) or from.is_a?(SeqExpr)
          raise Z3::Exception, "Re.Range takes single character Strings, not #{from.sort} values"
        end
        ReSort.new(from.sort).new(LowLevel.mk_re_range(from, to))
      end

      def Concat(*args)
        args = coerce_to_same_re_sort(*args)
        return args[0] if args.size == 1
        args[0].sort.new(LowLevel.mk_re_concat(args))
      end

      def Union(*args)
        args = coerce_to_same_re_sort(*args)
        return args[0] if args.size == 1
        args[0].sort.new(LowLevel.mk_re_union(args))
      end

      def Intersect(*args)
        args = coerce_to_same_re_sort(*args)
        return args[0] if args.size == 1
        args[0].sort.new(LowLevel.mk_re_intersect(args))
      end

      # Z3's `re.diff` is binary, unlike concat/union/intersect
      def Diff(a, b)
        a, b = coerce_to_same_re_sort(a, b)
        a.sort.new(LowLevel.mk_re_diff(a, b))
      end

      def Complement(re)
        ~coerce_to_same_re_sort(re)[0]
      end

      def Star(re)
        coerce_to_same_re_sort(re)[0].star
      end

      def Plus(re)
        coerce_to_same_re_sort(re)[0].plus
      end

      def Option(re)
        coerce_to_same_re_sort(re)[0].option
      end

      # Exactly `n` copies - `re.^`
      def Power(re, n)
        re = coerce_to_same_re_sort(re)[0]
        raise Z3::Exception, "Can only repeat a Re a non-negative Integer number of times" unless n.is_a?(Integer) and n >= 0
        re.sort.new(LowLevel.mk_re_power(re, n))
      end

      # Between `from` and `to` copies - `re.loop`. A `nil` upper bound is unbounded,
      # which Z3 spells as an upper bound of 0.
      def Loop(re, from, to=nil)
        re = coerce_to_same_re_sort(re)[0]
        raise Z3::Exception, "Re repetition count must be a non-negative Integer" unless from.is_a?(Integer) and from >= 0
        unless to.nil?
          raise Z3::Exception, "Re repetition count must be a non-negative Integer" unless to.is_a?(Integer) and to >= 0
          raise Z3::Exception, "Re repetition upper bound #{to} is below lower bound #{from}" if to < from
        end
        # Z3 reads an upper bound of 0 as "no upper bound", so `re * (0..0)` - the
        # regex matching only the empty sequence - has to go through `re.^` instead
        return re.sort.new(LowLevel.mk_re_power(re, 0)) if from == 0 and to == 0
        re.sort.new(LowLevel.mk_re_loop(re, from, to || 0))
      end

      # These three are the only regexes that need their sort spelled out, since
      # nothing about them says what they range over. It defaults to String.
      def Empty(seq_sort=StringSort.new)
        ReSort.new(seq_sort).empty
      end

      def Full(seq_sort=StringSort.new)
        ReSort.new(seq_sort).full
      end

      def AllChar(seq_sort=StringSort.new)
        ReSort.new(seq_sort).all_char
      end

      # The last index a Range covers, or nil if it has no end. `(2...5)` is `2..4`,
      # and `(2...)` is still endless.
      def range_end(range)
        return nil if range.end.nil?
        raise Z3::Exception, "Can only repeat a Re a Range of non-negative Integers" unless range.end.is_a?(Integer)
        range.exclude_end? ? range.end - 1 : range.end
      end
    end
  end

  # Regex code is nearly all constructors, and `Z3::Re.Union(a, b)` reads better than
  # `Z3::ReExpr.Union(a, b)`. It's the same class under a shorter name, not a second one.
  Re = ReExpr
end
