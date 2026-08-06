module Z3
  # Z3 has no String sort of its own - a String is a Seq(Char), and `str.++` is the
  # same operation as `seq.++`. The Exprs still don't share a hierarchy, because the
  # Ruby side of them doesn't: a SeqExpr should read like a Ruby Array and a
  # StringExpr like a Ruby String, and those two have no common ancestor either.
  # Where a seq and a string operation really are one Z3 operation, they share the
  # LowLevel call, not a superclass.
  #
  # That split is what settles the element-versus-subsequence question. Every Z3 seq
  # operation takes a subsequence, but Ruby's Array#include? / #index take an element,
  # and Ruby wins - as it does everywhere the two disagree: a bare element is wrapped
  # into a one element sequence, while a SeqExpr of this very sort or a Ruby Array is
  # taken as the subsequence it already is.
  class SeqExpr < Expr
    include SeqMapFold

    public_class_method :new

    def element_sort
      sort.element_sort
    end

    # Ruby Array has both #length and #size, so this has both too
    def length
      IntSort.new.new(LowLevel.mk_seq_length(self))
    end

    def size
      length
    end

    def empty?
      length == 0
    end

    # Ruby Array#+ is concatenation, and so is `seq.++`
    def +(other)
      SeqExpr.Concat(self, other)
    end

    # Ruby Array#* repeats. Only the Integer form - Array#*(String) is #join, and
    # there's no joining a sequence of arbitrary element sort into a String.
    def *(count)
      raise Z3::Exception, "Can only repeat a Seq a non-negative Integer number of times" unless count.is_a?(Integer) and count >= 0
      return sort.from_const([]) if count == 0
      SeqExpr.Concat(*([self] * count))
    end

    # Ruby Array#[]. `xs[i]` is the element (`seq.nth`), `xs[i, len]` and `xs[range]`
    # are subsequences (`seq.extract`).
    #
    # An index is an offset, and a negative one is not counted from the end the way
    # Ruby's is - see StringExpr#[] for why. Counting from the end is `xs[xs.length - 1]`,
    # which is what #last does. Out of range is whatever Z3 says: a subsequence is
    # empty, and an element is left *unspecified*, so an out of range `xs[i]` is a term
    # the solver may pick any value for. It denotes an element, and no element is `nil`.
    def [](index, len=nil)
      if len
        subseq(index, len)
      elsif index.is_a?(Range)
        subseq(*Expr.offset_and_length(index, length))
      else
        element_sort.new(LowLevel.mk_seq_nth(self, IntSort.new.cast(index)))
      end
    end

    # Ruby Array#slice is Array#[]
    alias_method :slice, :[]

    # Ruby Array#at - the element, same as `xs[i]`
    def at(index)
      self[index]
    end

    # Ruby Array#first / #last, including their "n of them" second form
    def first(n=nil)
      n ? subseq(0, n) : self[0]
    end

    def last(n=nil)
      n ? subseq(length - n, n) : self[length - 1]
    end

    # Ruby Array#include? takes an element, so that's what this expects - pass a
    # SeqExpr of this sort, or a Ruby Array, to ask about a subsequence instead
    def include?(element_or_subsequence)
      BoolSort.new.new(LowLevel.mk_seq_contains(self, cast_to_seq(element_or_subsequence)))
    end

    # Z3's `seq.prefixof` takes the prefix first and the sequence second. Ruby's Array
    # has no #start_with?, so String's spelling is reused, and like String's it holds
    # if any candidate matches.
    def start_with?(*prefixes)
      return BoolSort.new.False if prefixes.empty?
      matches = prefixes.map { |prefix|
        BoolSort.new.new(LowLevel.mk_seq_prefix(cast_to_seq(prefix), self))
      }
      # `Or` of one thing prints as `or(...)`, and every caller is more likely to pass one
      matches.size == 1 ? matches[0] : BoolExpr.Or(*matches)
    end

    def end_with?(*suffixes)
      return BoolSort.new.False if suffixes.empty?
      matches = suffixes.map { |suffix|
        BoolSort.new.new(LowLevel.mk_seq_suffix(cast_to_seq(suffix), self))
      }
      # `Or` of one thing prints as `or(...)`, and every caller is more likely to pass one
      matches.size == 1 ? matches[0] : BoolExpr.Or(*matches)
    end

    # Ruby Array#index. This denotes an Int, so there's no `nil` available for it to be
    # when there's no match - `seq.indexof` answers -1, and that's what comes back. It
    # also takes a starting offset, which Ruby's Array#index doesn't.
    def index(element_or_subsequence, offset=0)
      IntSort.new.new(LowLevel.mk_seq_index(self, cast_to_seq(element_or_subsequence), IntSort.new.cast(offset)))
    end

    # Ruby Array#rindex. Z3's `seq.last_indexof` takes no offset, so neither does this.
    def rindex(element_or_subsequence)
      IntSort.new.new(LowLevel.mk_seq_last_index(self, cast_to_seq(element_or_subsequence)))
    end

    # `seq.in_re`, the same operation as StringExpr#matches? and named the same way -
    # see there for why it isn't `match?`, and why the argument is never converted
    def matches?(re)
      BoolSort.new.new(LowLevel.mk_seq_in_re(self, ReExpr.expect_re_over(re, sort)))
    end

    # Ruby Array has nothing like these, so they keep String's names along with
    # String's first-one versus every-one split. The pattern can be a ReExpr here
    # too, which is the one argument that isn't read as an element-or-subsequence -
    # and which Z3 4.16 can build but not yet reason about, see StringExpr#sub.
    def sub(pattern, replacement)
      if pattern.is_a?(ReExpr)
        sort.new(LowLevel.mk_seq_replace_re(self, ReExpr.expect_re_over(pattern, sort), cast_to_seq(replacement)))
      else
        sort.new(LowLevel.mk_seq_replace(self, cast_to_seq(pattern), cast_to_seq(replacement)))
      end
    end

    def gsub(pattern, replacement)
      if pattern.is_a?(ReExpr)
        sort.new(LowLevel.mk_seq_replace_re_all(self, ReExpr.expect_re_over(pattern, sort), cast_to_seq(replacement)))
      else
        sort.new(LowLevel.mk_seq_replace_all(self, cast_to_seq(pattern), cast_to_seq(replacement)))
      end
    end

    # A Ruby Array out of a sequence value, with #value called on every element - so a
    # Seq(Seq(Int)) gives nested Arrays, the way StringExpr#value gives a Ruby String.
    #
    # Deliberately not #to_ary: that's Ruby's implicit conversion protocol, and no
    # expression can promise to be an Array. See StringExpr#value, which says the same
    # about #to_str.
    def value
      elements = seq_elements || simplify.seq_elements
      raise Z3::Exception, "Can't convert expression #{self} into Array" unless elements
      elements.map(&:value)
    end

    class << self
      # A one element sequence. Z3 needs these to build any sequence value at all,
      # and they're what makes the element-taking methods above work.
      def Unit(element)
        SeqSort.new(element.sort).new(LowLevel.mk_seq_unit(element))
      end

      def coerce_to_same_seq_sort(*args)
        args = coerce_to_same_sort(*args)
        raise Z3::Exception, "Seq value with same element sort expected" unless args[0].is_a?(SeqExpr)
        args
      end

      def Concat(*args)
        raise Z3::Exception, "Concat requires at least one argument" if args.empty?
        args = coerce_to_same_seq_sort(*args)
        # Z3 rejects a concatenation of fewer than two sequences
        return args[0] if args.size == 1
        args[0].sort.new(LowLevel.mk_seq_concat(args))
      end
    end

    protected

    # The elements of a sequence value, or nil if this isn't one. Z3 has no sequence
    # literal - a value is `seq.empty`, a one element `seq.unit`, or a concatenation of
    # those, which models return nested any which way, so the whole spine gets walked.
    def seq_elements
      return nil unless ast_kind == :app
      case func_decl.name
      when "seq.empty"
        []
      when "seq.unit"
        arguments
      when "seq.++"
        arguments.each_with_object([]) do |arg, elements|
          part = arg.seq_elements
          return nil unless part
          elements.concat(part)
        end
      end
    end

    private

    # `seq.extract`, with the offset already counted from the end if it was negative.
    # `xs[offset, len]` is the Ruby spelling, so that's the only one exposed.
    def subseq(offset, len)
      sort.new(LowLevel.mk_seq_extract(self, IntSort.new.cast(offset), IntSort.new.cast(len)))
    end

    # A sequence of this very sort, or a Ruby Array, is already the subsequence it
    # looks like. Anything else is an element, and becomes a one element sequence -
    # which is also the only reading available when the element sort is itself a Seq.
    def cast_to_seq(other)
      return other if other.is_a?(SeqExpr) and other.sort == sort
      return sort.from_const(other) if other.is_a?(Array)
      SeqExpr.Unit(element_sort.cast(other))
    end
  end
end
