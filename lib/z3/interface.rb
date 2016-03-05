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

  def Bitval(n, v)
    BitvalSort.new(n).var(v)
  end

  def True
    BoolSort.new.True
  end

  def False
    BoolSort.new.False
  end

  def And(*args)
    args = coerce_to_same_bool_sort(*args)
    BoolSort.new.new(Z3::LowLevel.mk_and(args))
  end

  def Or(*args)
    args = coerce_to_same_bool_sort(*args)
    BoolSort.new.new(Z3::LowLevel.mk_or(args))
  end

  def Implies(a,b)
    a, b = coerce_to_same_bool_sort(a, b)
    BoolSort.new.new(Z3::LowLevel.mk_implies(a, b))
  end

  def Iff(a,b)
    a, b = coerce_to_same_bool_sort(a, b)
    BoolSort.new.new(Z3::LowLevel.mk_iff(a, b))
  end

  def Add(*args)
    raise ArgumentError if args.empty?
    args = coerce_to_same_arith_sort(*args)
    args[0].sort.new(LowLevel.mk_add(args))
  end

  def Sub(a,b)
    a, b = coerce_to_same_arith_sort(a, b)
    a.sort.new(LowLevel.mk_sub([a, b]))
  end

  def Mul(*args)
    args = coerce_to_same_arith_sort(*args)
    args[0].sort.new(LowLevel.mk_mul(args))
  end

  def Div(a,b)
    a, b = coerce_to_same_arith_sort(a, b)
    a.sort.new(LowLevel.mk_div(a, b))
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
    BoolSort.new.new(LowLevel.mk_gt(a, b))
  end

  def Ge(a, b)
    a, b = coerce_to_same_sort(a, b)
    BoolSort.new.new(LowLevel.mk_ge(a, b))
  end

  def Lt(a, b)
    a, b = coerce_to_same_sort(a, b)
    BoolSort.new.new(LowLevel.mk_lt(a, b))
  end

  def Le(a, b)
    a, b = coerce_to_same_sort(a, b)
    BoolSort.new.new(LowLevel.mk_le(a, b))
  end

  def Not(a)
    a = Value.from_const(a) unless a.is_a?(Value)
    raise Z3::Exception, "No idea how to autoconvert `#{a.class}': `#{a.inspect}'" unless a.is_a?(BoolValue)
    BoolSort.new.new(LowLevel.mk_not(a))
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
    max_sort = args.map{|a| a.is_a?(Value) ? a.sort : Value.sort_for_const(a)}.max
    args.map do |a|
      if a.is_a?(Value)
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
    raise Z3::Exception, "Bool value expected" unless args[0].is_a?(BoolValue)
    args
  end

  def coerce_to_same_arith_sort(*args)
    args = coerce_to_same_sort(*args)
    raise Z3::Exception, "Int or Real value expected" unless args[0].is_a?(IntValue) or args[0].is_a?(RealValue)
    args
  end

  class << self
    include Z3
  end
end
