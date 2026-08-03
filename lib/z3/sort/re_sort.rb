module Z3
  class ReSort < Sort
    attr_reader :seq_sort
    def initialize(seq_sort)
      @seq_sort = seq_sort
      super LowLevel.mk_re_sort(seq_sort)
    end

    def expr_class
      ReExpr
    end

    # Z3 has no regex literals, and nothing converts a Ruby Regexp - see ReExpr for
    # why. What does convert is a sequence: `seq.to_re` is the regex matching exactly
    # that one sequence, so a Ruby String converts to a `Re(String)` and a Ruby Array
    # to a `Re(Seq(...))`, through the basis sort's own conversion.
    def from_const(val)
      new(LowLevel.mk_seq_to_re(seq_sort.from_const(val)))
    end

    # The same conversion for a sequence that's already an Expr, so a StringExpr or a
    # SeqExpr of the basis sort can stand in for a regex too
    def from_value(v)
      return v if v.sort == self
      raise Z3::Exception, "Can't convert #{v.sort} into #{self}" unless v.sort == seq_sort
      new(LowLevel.mk_seq_to_re(v))
    end

    # `re.none`, `re.all` and `re.allchar` - the empty language, every sequence, and
    # every one element sequence. Values rather than operations, so they live here
    # the way BoolSort#True does.
    def empty
      new(LowLevel.mk_re_empty(self))
    end

    def full
      new(LowLevel.mk_re_full(self))
    end

    def all_char
      new(LowLevel.mk_re_allchar(self))
    end

    def to_s
      "Re(#{seq_sort})"
    end

    def inspect
      "ReSort(#{seq_sort})"
    end

    public_class_method :new
  end
end
