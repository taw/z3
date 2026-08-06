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

  # Cardinality constraints, which Z3 solves natively instead of unfolding into
  # arithmetic. A list bounds how many of the Bools are true:
  #
  #   Z3.AtMost([a, b, c], 2)
  #
  # An `expr => weight` Hash bounds the total weight of the true ones instead, which
  # is the knapsack shape - `a` costs 3, `b` costs 2, `c` costs 5, spend at most 7:
  #
  #   Z3.AtMost({a => 3, b => 2, c => 5}, 7)
  #
  # Weights are Integers and may be negative or zero, and so may the bound in the
  # weighted form - a total, unlike a count, has no floor at 0. All weights being 1
  # builds the very same term the list form builds.
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

  # Z3's global parameters, the ones the `z3` binary takes on its command line. Names
  # are case insensitive, and the ones belonging to a module are qualified with it -
  # `smt.qi.cost`, `pp.decimal`. Everything is a String in both directions, which is
  # Z3's own interface to these and not a choice made here.
  #
  # Z3 doesn't raise on a name it doesn't have, it prints a warning and carries on,
  # so the name is checked here first - the same reason Params checks its own against
  # a ParamDescrs. A value it can't use is only warned about too, and can't be checked
  # in the same way, so #get_param is how to see whether one took.
  def set_param(name, value)
    name = name.to_s
    raise Z3::Exception, "Unknown parameter `#{name}'" unless known_global_param?(name)
    LowLevel.global_param_set(name, value.to_s)
    value
  end

  # nil for a parameter Z3 doesn't have. Note that the module qualified ones only
  # answer once the module has been loaded, which for most of them means after the
  # first solve.
  def get_param(name)
    name = name.to_s
    return nil unless known_global_param?(name)
    LowLevel.global_param_get(name)
  end

  # Puts every global parameter back to its default
  def reset_params
    LowLevel.global_param_reset_all
    nil
  end

  # The global parameters, the way Solver and Tactic each describe their own. Only the
  # unqualified ones are in here - the modules describe theirs separately, and Z3
  # offers no way to reach those.
  def param_descrs
    ParamDescrs.new(LowLevel.get_global_param_descrs)
  end

  # Every parameter AST#simplify takes, the way Solver and Tactic describe their own.
  # These are the rewriter's, and they're nothing to do with the global ones above.
  def simplify_param_descrs
    ParamDescrs.new(LowLevel.simplify_get_param_descrs)
  end

  # The same set as one block of text, which is what Z3 offers instead of a
  # description per parameter - ParamDescrs#documentation takes them one at a time
  def simplify_help
    LowLevel.simplify_get_help
  end

  private

  # Whether Z3 could have this parameter. Only the unqualified names can be told -
  # a module qualified one isn't in the descriptions and there's no way to ask the
  # module for its own, so those are taken at face value. Z3 lowercases a name on the
  # way in, while the descriptions keep them as they were declared.
  #
  # Worth the lookup because Z3's answer to an unknown name is a warning followed by
  # every legal parameter, all of it on stderr, and none of it an error.
  def known_global_param?(name)
    name.include?(".") or param_descrs.include?(name.downcase)
  end

  public

  # This is only so these can be called as `Z3.Int("x")`. Including Z3 into your own
  # code is not supported - `Z3#String` shadows the private `Kernel#String`, and the
  # `Z3::Exception` constant shadows `::Exception`, so `rescue Exception` would quietly
  # stop catching anything that isn't ours.
  class << self
    include Z3
  end
end
