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

  # A function which *is* its body, rather than one the solver gets to interpret -
  # SMT-LIB's `define-fun-rec`. Signature order is the same as Z3.Function's.
  #
  #   fact = Z3.RecFunction("fact", Int, Int) { |fact, n| Z3.IfThenElse(n <= 0, 1, n * fact[n - 1]) }
  #   solver.assert fact[5] == x   # x is 120
  #
  # The block gets the function itself as its first argument, then one variable per
  # domain sort. Without a block the declaration comes back undefined and `#define`
  # supplies the body later, which is how mutually recursive functions are written.
  def RecFunction(name, *sorts, &block)
    FuncDecl.declare_rec(name, *sorts, &block)
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
    warn_about_proof_param if name.downcase == "proof"
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

  # Z3's own estimate of what it has allocated, in bytes. Process wide rather than
  # per context - it's the one Z3 function that takes no context at all, and there's
  # only ever one context here anyway.
  #
  # What it's good for is watching the leak the README warns about. The context is
  # built with `Z3_mk_context` rather than `Z3_mk_context_rc`, which means ASTs live
  # as long as the context does and nothing Z3 hash-conses is ever released, so this
  # number goes up and effectively never comes down. Dropping every reference to
  # every Expr and running Ruby's GC doesn't move it. Only the refcounted objects -
  # `Solver`, `Model`, `Tactic` and the rest - are released, and they're the smaller
  # half.
  def estimated_alloc_size
    LowLevel.get_estimated_alloc_size
  end

  # Makes Z3's reference count decrements thread safe. They are not by default, which
  # Z3's own header states plainly.
  #
  # It matters here because every refcounted object is released from an ObjectSpace
  # finalizer, and a finalizer runs on whichever thread happened to trigger the
  # collection - not necessarily the one that built the object. A single threaded
  # program has nothing to fix, since there's only one thread for either to run on.
  # A threaded one does, and the failure would be a corrupted refcount rather than
  # anything that announces itself.
  #
  # One way, as Z3 offers no way back off, and harmless to call more than once.
  # It cost nothing measurable over 30k create-and-collect cycles, so a program with
  # threads in it should just call this before starting them.
  #
  # This is not the same subject as the note above: that's about memory never being
  # freed, this is about freeing it safely from more than one thread. Neither makes
  # a `Context` safe to *use* from several threads, which Z3 doesn't support at all
  # without a context per thread - and this gem has exactly one.
  def enable_concurrent_dec_ref
    LowLevel.enable_concurrent_dec_ref
    nil
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

  # `proof` is the one global parameter Z3 reads only while creating the context -
  # its own description says "it must be enabled when the Z3 context is created" -
  # and the context is created while `z3` is being required, so by the time anyone
  # can call #set_param it's far too late. Setting it is harmless, and #get_param
  # will report it as set, which is exactly the problem worth warning about: Z3
  # goes on refusing to produce proofs. Every other global parameter, `timeout` and
  # `encoding` included, takes effect whenever it's set.
  def warn_about_proof_param
    warn "Z3.set_param(\"proof\", ...) has no effect - proofs must be enabled before " \
         "the context is created, which happens while `z3` is being required. " \
         "Z3_solver_get_proof will keep saying there is no current proof."
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
