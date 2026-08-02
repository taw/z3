module Z3
  # Z3 has no String sort of its own - a String is a Seq(Char), and `str.++` is the
  # same operation as `seq.++`. The Exprs still don't share a hierarchy, because the
  # Ruby side of them doesn't: a SeqExpr should read like a Ruby Array and a
  # StringExpr like a Ruby String, and those two have no common ancestor either.
  # Where a seq and a string operation really are one Z3 operation, they share the
  # LowLevel call, not a superclass.
  class SeqExpr < Expr
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
  end
end
