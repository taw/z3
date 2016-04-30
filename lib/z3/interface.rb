module Z3
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

  def True
    BoolSort.new.True
  end

  def False
    BoolSort.new.False
  end

  def Const(v)
    Expr.sort_for_const(v).from_const(v)
  end

  def And(*args)
    args = coerce_to_same_sort(*args)
    case args[0]
    when BoolExpr
      BoolSort.new.new(Z3::LowLevel.mk_and(args))
    when BitvecExpr
      args.inject do |a,b|
        a.sort.new(Z3::LowLevel.mk_bvand(a, b))
      end
    else
      raise Z3::Exception, "Can't perform logic operations on #{a.sort} exprs, only Bool and Bitvec"
    end
  end

  def Or(*args)
    args = coerce_to_same_sort(*args)
    case args[0]
    when BoolExpr
      BoolSort.new.new(Z3::LowLevel.mk_or(args))
    when BitvecExpr
      args.inject do |a,b|
        a.sort.new(Z3::LowLevel.mk_bvor(a, b))
      end
    else
      raise Z3::Exception, "Can't perform logic operations on #{a.sort} exprs, only Bool and Bitvec"
    end
  end

  def Xor(*args)
    args = coerce_to_same_sort(*args)
    case args[0]
    when BoolExpr
      args.inject do |a,b|
        BoolSort.new.new(Z3::LowLevel.mk_xor(a, b))
      end
    when BitvecExpr
      args.inject do |a,b|
        a.sort.new(Z3::LowLevel.mk_bvxor(a, b))
      end
    else
      raise Z3::Exception, "Can't perform logic operations on #{a.sort} exprs, only Bool and Bitvec"
    end
  end

  def Implies(a,b)
    a, b = coerce_to_same_bool_sort(a, b)
    BoolSort.new.new(Z3::LowLevel.mk_implies(a, b))
  end

  def Iff(a,b)
    a, b = coerce_to_same_bool_sort(a, b)
    BoolSort.new.new(Z3::LowLevel.mk_iff(a, b))
  end

  def IfThenElse(a, b, c)
    a, = coerce_to_same_bool_sort(a)
    b, c = coerce_to_same_sort(b, c)
    b.sort.new(Z3::LowLevel.mk_ite(a, b, c))
  end

  def Add(*args)
    raise Z3::Exception if args.empty?
    args = coerce_to_same_sort(*args)
    case args[0]
    when ArithExpr
      args[0].sort.new(LowLevel.mk_add(args))
    when BitvecExpr
      args.inject do |a,b|
        a.sort.new(LowLevel.mk_bvadd(a,b))
      end
    else
      raise Z3::Exception, "Can't perform logic operations on #{args[0].sort} exprs, only Int/Real/Bitvec"
    end
  end

  def Sub(*args)
    args = coerce_to_same_sort(*args)
    case args[0]
    when ArithExpr
      args[0].sort.new(LowLevel.mk_sub(args))
    when BitvecExpr
      args.inject do |a,b|
        a.sort.new(LowLevel.mk_bvsub(a,b))
      end
    else
      raise Z3::Exception, "Can't perform logic operations on #{args[0].sort} values, only Int/Real/Bitvec"
    end
  end

  def Mul(*args)
    args = coerce_to_same_sort(*args)
    case args[0]
    when ArithExpr
      args[0].sort.new(LowLevel.mk_mul(args))
    when BitvecExpr
      args.inject do |a,b|
        a.sort.new(LowLevel.mk_bvmul(a,b))
      end
    else
      raise Z3::Exception, "Can't perform logic operations on #{args[0].sort} values, only Int/Real/Bitvec"
    end
  end

  def Div(a,b)
    a, b = coerce_to_same_arith_sort(a, b)
    a.sort.new(LowLevel.mk_div(a, b))
  end

  def Mod(a,b)
    a, b = coerce_to_same_int_sort(a, b)
    a.sort.new(LowLevel.mk_mod(a, b))
  end

  def Rem(a,b)
    a, b = coerce_to_same_int_sort(a, b)
    a.sort.new(LowLevel.mk_rem(a, b))
  end

  def Power(a, b)
    # Wait, is this even legitimate that it's I**I and R**R?
    a, b = coerce_to_same_arith_sort(a, b)
    a.sort.new(LowLevel.mk_power(a, b))
  end

  def Eq(a, b)
    a, b = coerce_to_same_sort(a, b)
    BoolSort.new.new(LowLevel.mk_eq(a, b))
  end

  def Distinct(*args)
    args = coerce_to_same_sort(*args)
    BoolSort.new.new(LowLevel.mk_distinct(args))
  end

  def Gt(a, b)
    a, b = coerce_to_same_sort(a, b)
    case a
    when ArithExpr
      BoolSort.new.new(LowLevel.mk_gt(a, b))
    when BitvecExpr
      raise Z3::Exception, "Use #signed_gt or #unsigned_gt for Bitvec, not >"
    else
      raise Z3::Exception, "Can't compare #{a.sort} values"
    end
  end

  def Ge(a, b)
    a, b = coerce_to_same_sort(a, b)
    case a
    when ArithExpr
      BoolSort.new.new(LowLevel.mk_ge(a, b))
    when BitvecExpr
      raise Z3::Exception, "Use #signed_ge or #unsigned_ge for Bitvec, not >="
    else
      raise Z3::Exception, "Can't compare #{a.sort} values"
    end
  end

  def Lt(a, b)
    a, b = coerce_to_same_sort(a, b)
    case a
    when ArithExpr
      BoolSort.new.new(LowLevel.mk_lt(a, b))
    when BitvecExpr
      raise Z3::Exception, "Use #signed_lt or #unsigned_lt for Bitvec, not <"
    else
      raise Z3::Exception, "Can't compare #{a.sort} values"
    end
  end

  def Le(a, b)
    a, b = coerce_to_same_sort(a, b)
    case a
    when ArithExpr
      BoolSort.new.new(LowLevel.mk_le(a, b))
    when BitvecExpr
      raise Z3::Exception, "Use #signed_le or #unsigned_le for Bitvec, not <="
    else
      raise Z3::Exception, "Can't compare #{a.sort} values"
    end
  end

  def UnsignedGt(a, b)
    a, b = coerce_to_same_bv_sort(a, b)
    BoolSort.new.new(Z3::LowLevel.mk_bvugt(a, b))
  end

  def UnsignedGe(a, b)
    a, b = coerce_to_same_bv_sort(a, b)
    BoolSort.new.new(Z3::LowLevel.mk_bvuge(a, b))
  end

  def UnsignedLt(a, b)
    a, b = coerce_to_same_bv_sort(a, b)
    BoolSort.new.new(Z3::LowLevel.mk_bvult(a, b))
  end

  def UnsignedLe(a, b)
    a, b = coerce_to_same_bv_sort(a, b)
    BoolSort.new.new(Z3::LowLevel.mk_bvule(a, b))
  end

  def SignedGt(a, b)
    a, b = coerce_to_same_bv_sort(a, b)
    BoolSort.new.new(Z3::LowLevel.mk_bvsgt(a, b))
  end

  def SignedGe(a, b)
    a, b = coerce_to_same_bv_sort(a, b)
    BoolSort.new.new(Z3::LowLevel.mk_bvsge(a, b))
  end

  def SignedLt(a, b)
    a, b = coerce_to_same_bv_sort(a, b)
    BoolSort.new.new(Z3::LowLevel.mk_bvslt(a, b))
  end

  def SignedLe(a, b)
    a, b = coerce_to_same_bv_sort(a, b)
    BoolSort.new.new(Z3::LowLevel.mk_bvsle(a, b))
  end

  def Not(a)
    a = Value.from_const(a) unless a.is_a?(Value)
    raise Z3::Exception, "No idea how to autoconvert `#{a.class}': `#{a.inspect}'" unless a.is_a?(BoolValue)
    BoolSort.new.new(LowLevel.mk_not(a))
  end

  # Presume arithmetic (sign-extend)
  def RShift(a, b)
    a, b = coerce_to_same_bv_sort(a, b)
    a.sort.new(LowLevel.mk_bvashr(a, b))
  end

  def LShift(a, b)
    a, b = coerce_to_same_bv_sort(a, b)
    a.sort.new(LowLevel.mk_bvshl(a, b))
  end

  def version
    LowLevel.get_version.join(".")
  end

  def set_param(k,v)
    LowLevel.global_param_set(k,v)
  end

  private

  def coerce_to_same_sort(*args)
    # This will raise exception unless one of the sorts is highest
    # So [true, IntSort]
    max_sort = args.map{|a| a.is_a?(Expr) ? a.sort : Expr.sort_for_const(a)}.max
    args.map do |a|
      if a.is_a?(Expr)
        if  a.sort == max_sort
          a
        else
          max_sort.from_value(a)
        end
      else
        max_sort.from_const(a)
      end
    end
  end

  def coerce_to_same_bool_sort(*args)
    args = coerce_to_same_sort(*args)
    raise Z3::Exception, "Bool value expected" unless args[0].is_a?(BoolExpr)
    args
  end

  def coerce_to_same_arith_sort(*args)
    args = coerce_to_same_sort(*args)
    raise Z3::Exception, "Int or Real value expected" unless args[0].is_a?(IntExpr) or args[0].is_a?(RealExpr)
    args
  end

  def coerce_to_same_bv_sort(*args)
    args = coerce_to_same_sort(*args)
    raise Z3::Exception, "Bitvec value with same size expected" unless args[0].is_a?(BitvecExpr)
    args
  end

  def coerce_to_same_int_sort(*args)
    args = coerce_to_same_sort(*args)
    raise Z3::Exception, "Int value expected" unless args[0].is_a?(IntExpr)
    args
  end

  class << self
    include Z3
  end
end
