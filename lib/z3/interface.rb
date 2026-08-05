module Z3
  #--
  # Variables
  #++
  def Int(v)
    IntSort.new.var(v)
  end

  def Real(v)
    RealSort.new.var(v)
  end

  def Bool(v)
    BoolSort.new.var(v)
  end

  def Bitvec(v, n)
    BitvecSort.new(n).var(v)
  end

  def String(v)
    StringSort.new.var(v)
  end

  #--
  # Constants
  #++
  def True
    BoolSort.new.True
  end

  def False
    BoolSort.new.False
  end

  def Const(v)
    Expr.sort_for_const(v).from_const(v)
  end

  # An uninterpreted function - a symbol the solver gets to decide the meaning of.
  # The last sort is the range and the ones before it are the domain, the same order
  # SMT-LIB's `declare-fun` uses, so `Z3.Function("f", Int, Int, Bool)` is a two
  # argument predicate. Apply it with `f[x, y]`.
  def Function(name, *sorts)
    FuncDecl.declare(name, *sorts)
  end

  # Same, but Z3 picks a name nothing has used yet by appending a number to `prefix` -
  # for helper functions which shouldn't collide with whatever the caller has named.
  # The number comes from a counter shared by the whole context, so don't count on
  # getting any particular one.
  def FreshFunction(prefix, *sorts)
    FuncDecl.declare_fresh(prefix, *sorts)
  end

  #--
  # Quantifiers
  #++

  # `bound` is the variable, or variables, the quantifier binds - the very same ones
  # the body was built out of, which Z3 rebinds inside it. Everywhere else they go on
  # meaning what they always did.
  #
  #   Z3.ForAll(x, f[x] > 0)
  #   Z3.Exists([x, y], f[x] == y)
  #
  # A quantified problem is a different kind of problem: `Solver#check` can return
  # `:unknown`, and on some inputs it doesn't return at all - set `timeout` or
  # `rlimit` on the solver if that matters.
  def ForAll(bound, body)
    Expr.ForAll(bound, body)
  end

  def Exists(bound, body)
    Expr.Exists(bound, body)
  end

  # An anonymous function, which comes back as an Array - `Z3.Lambda(x, x * 2)[3]` is 6
  def Lambda(bound, body)
    Expr.Lambda(bound, body)
  end

  #--
  # Multiargument constructors
  #++
  def Distinct(*args)
    Expr.Distinct(*args)
  end

  def Eq(*args)
    Expr.Eq(*args)
  end

  def Add(*args)
    Expr.Add(*args)
  end

  def Mul(*args)
    Expr.Mul(*args)
  end

  def Or(*args)
    BoolExpr.Or(*args)
  end

  def And(*args)
    BoolExpr.And(*args)
  end

  def Xor(*args)
    Expr.Xor(*args)
  end

  def Implies(a,b)
    BoolExpr.Implies(a,b)
  end

  def IfThenElse(a,b,c)
    BoolExpr.IfThenElse(a,b,c)
  end

  def AtMost(args, k)
    BoolExpr.AtMost(args, k)
  end

  def AtLeast(args, k)
    BoolExpr.AtLeast(args, k)
  end

  def Exactly(args, k)
    BoolExpr.Exactly(args, k)
  end

  #--
  # Global functions
  #++
  def version
    LowLevel.get_version.join(".")
  end

  def version_at_least?(a, b=0, c=0, d=0)
    (LowLevel.get_version <=> [a, b, c, d]) >= 0
  end

  def set_param(k,v)
    LowLevel.global_param_set(k,v)
  end

  # This is only so these can be called as `Z3.Int("x")`. Including Z3 into your own
  # code is not supported - `Z3#String` shadows the private `Kernel#String`, and the
  # `Z3::Exception` constant shadows `::Exception`, so `rescue Exception` would quietly
  # stop catching anything that isn't ours.
  class << self
    include Z3
  end
end
