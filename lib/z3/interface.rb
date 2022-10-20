# Everything here might go away
module Z3
  # Variables
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

  # Constants
  def True
    BoolSort.new.True
  end

  def False
    BoolSort.new.False
  end

  def Const(v)
    Expr.sort_for_const(v).from_const(v)
  end

  # Multiargument constructors
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

  # Global functions
  def version
    LowLevel.get_version.join(".")
  end

  def version_at_least?(a, b=0, c=0, d=0)
    (LowLevel.get_version <=> [a, b, c, d]) >= 0
  end

  def set_param(k,v)
    LowLevel.global_param_set(k,v)
  end

  class << self
    include Z3
  end
end
