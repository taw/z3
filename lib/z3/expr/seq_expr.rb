module Z3
  # Z3 has no String sort of its own - a String is a Seq(Char), and `str.++` is the
  # same operation as `seq.++`. The Exprs still don't share a hierarchy, because the
  # Ruby side of them doesn't: a SeqExpr should read like a Ruby Array and a
  # StringExpr like a Ruby String, and those two have no common ancestor either.
  # Where a seq and a string operation really are one Z3 operation, they'll share the
  # LowLevel call, not a superclass.
  class SeqExpr < Expr
    public_class_method :new
  end
end
