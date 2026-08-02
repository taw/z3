module Z3
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
  end
end
