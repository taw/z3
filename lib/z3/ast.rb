class Z3::Ast
  attr_reader :_ast
  # Do not use .new directly
  def initialize(_ast)
    @_ast = _ast
  end

  def sort
    Z3::Sort.new(Z3::LowLevel.get_sort(self))
  end

  def to_s
    Z3::LowLevel.ast_to_string(self)
  end

  def inspect
    "Z3::Ast<#{to_s} :: #{sort.to_s}>"
  end

  def ~
    raise Z3::Exception, "Can only be used on booleans" unless bool?
    Z3::Ast.not(self)
  end

  def int?
    sort == Z3::Sort.int
  end

  def bool?
    sort == Z3::Sort.bool
  end

  def real?
    sort == Z3::Sort.real
  end

  private def binary_arithmetic_operator(op, b)
    b = Z3::Ast.from_const(b, sort) unless b.is_a?(Z3::Ast)
    raise Z3::Exception, "Can't be used on booleans" if bool? or b.bool?
    if sort == b.sort
      a = self
    else
      a, b = Z3::Ast.coerce_to_same_sort(self, b)
    end
    Z3::Ast.send(op, a, b)
  end

  private def binary_int_operator(op, b)
    b = Z3::Ast.from_const(b, sort) unless b.is_a?(Z3::Ast)
    raise Z3::Exception, "Can only be used on integers" unless int? and b.int?
    Z3::Ast.send(op, a, b)
  end

  def |(b)
    b = Z3::Ast.from_const(b, sort) unless b.is_a?(Z3::Ast)
    raise Z3::Exception, "Can only be used on booleans" unless bool? and b.bool?
    Z3::Ast.or(self, b)
  end

  def &(b)
    b = Z3::Ast.from_const(b, sort) unless b.is_a?(Z3::Ast)
    raise Z3::Exception, "Can only be used on booleans" unless bool? and b.bool?
    Z3::Ast.and(self, b)
  end

  def +(b)
    binary_arithmetic_operator(:add, b)
  end

  def *(b)
    binary_arithmetic_operator(:mul, b)
  end

  def -(b)
    binary_arithmetic_operator(:sub, b)
  end

  def >=(b)
    binary_arithmetic_operator(:ge, b)
  end

  def >(b)
    binary_arithmetic_operator(:gt, b)
  end

  def <=(b)
    binary_arithmetic_operator(:le, b)
  end

  def <(b)
    binary_arithmetic_operator(:lt, b)
  end

  def **(b)
    binary_arithmetic_operator(:power, b)
  end

  def /(b)
    binary_arithmetic_operator(:div, b)
  end

  def %(b)
    binary_int_operator(:mod, b)
  end

  def rem(b)
    binary_int_operator(:rem, b)
  end

  def -@
    raise "Can only apply unary negation to Int or Real" unless int? or real?
    Z3::Ast.new(Z3::LowLevel.mk_unary_minus(self))
  end

  def ==(b)
    b = Z3::Ast.from_const(b, sort) unless b.is_a?(Z3::Ast)
    if sort != b.sort
      a, b = Z3::Ast.coerce_to_same_sort(self, b)
    else
      a = self
    end
    Z3::Ast.eq(self, b)
  end

  def !=(b)
    b = Z3::Ast.from_const(b, sort) unless b.is_a?(Z3::Ast)
    if sort != b.sort
      a, b = Z3::Ast.coerce_to_same_sort(self, b)
    else
      a = self
    end
    Z3::Ast.distinct(a, b)
  end

  def coerce(other)
    [Z3::Ast.from_const(other, sort), self]
  end

  def int_to_real
    raise Z3::Exception, "Type mismatch" unless int?
    Z3::Ast.new(Z3::LowLevel.mk_int2real(self))
  end

  class <<self
    def from_const(value, sort)
      case sort
      when Z3::Sort.bool
        raise Z3::Exception, "Can't convert #{value.class} to Bool" unless value == true or value == false
        if value
          Z3::Ast.true
        else
          Z3::Ast.false
        end
      when Z3::Sort.int
        # (int_var == 2.4) gets changed to
        # ((int_to_real int_var) == (mknumeral 2.4))
        raise Z3::Exception, "Can't convert #{value.class} to Real" unless value.is_a?(Numeric)
        if value.is_a?(Float)
          Z3::Ast.new(Z3::LowLevel.mk_numeral(value.to_s, Z3::Sort.real))
        else
          Z3::Ast.new(Z3::LowLevel.mk_numeral(value.to_s, sort))
        end
      when Z3::Sort.real
        raise Z3::Exception, "Can't convert #{value.class} to Real" unless value.is_a?(Numeric)
        Z3::Ast.new(Z3::LowLevel.mk_numeral(value.to_s, sort))
      end
    end

    def coerce_bool(value)
      if value.is_a?(Z3::Ast)
        return value if value.bool?
        raise Z3::Exception, "Can't convert #{value.sort} to Bool"
      end
      raise Z3::Exception, "Can't convert #{value.class} to Bool" unless value == true or value == false
        if value
          Z3::Ast.true
        else
          Z3::Ast.false
        end
    end

    def coerce_to_same_sort(a, b)
      if a.sort == Z3::Sort.int and b.sort == Z3::Sort.real
        [a.int_to_real, b]
      elsif b.sort == Z3::Sort.int and a.sort == Z3::Sort.real
        [a, b.int_to_real]
      else
        raise Z3::Exception, "No rules how to coerce #{a.sort} and #{b.sort}"
      end
    end

    def true
      Z3::Ast.new(Z3::LowLevel.mk_true)
    end

    def false
      Z3::Ast.new(Z3::LowLevel.mk_false)
    end

    def eq(a, b)
      Z3::Ast.new(Z3::LowLevel.mk_eq(a, b))
    end

    def ge(a, b)
      Z3::Ast.new(Z3::LowLevel.mk_ge(a, b))
    end

    def gt(a, b)
      Z3::Ast.new(Z3::LowLevel.mk_gt(a, b))
    end

    def le(a, b)
      Z3::Ast.new(Z3::LowLevel.mk_le(a, b))
    end

    def lt(a, b)
      Z3::Ast.new(Z3::LowLevel.mk_lt(a, b))
    end

    def power(a, b)
      Z3::Ast.new(Z3::LowLevel.mk_power(a, b))
    end

    def div(a, b)
      Z3::Ast.new(Z3::LowLevel.mk_div(a, b))
    end

    def mod(a, b)
      Z3::Ast.new(Z3::LowLevel.mk_mod(a, b))
    end

    def rem(a, b)
      Z3::Ast.new(Z3::LowLevel.mk_rem(a, b))
    end

    def not(a)
      a = coerce_bool(a)
      Z3::Ast.new(Z3::LowLevel.mk_not(a))
    end

    def distinct(*args)
      Z3::Ast.new(Z3::LowLevel.mk_distinct(args))
    end

    def and(*args)
      args = args.map{|a| coerce_bool(a)}
      Z3::Ast.new(Z3::LowLevel.mk_and(args))
    end

    def or(*args)
      args = args.map{|a| coerce_bool(a)}
      Z3::Ast.new(Z3::LowLevel.mk_or(args))
    end

    def add(*args)
      Z3::Ast.new(Z3::LowLevel.mk_add(args))
    end

    def iff(a, b)
      a = coerce_bool(a)
      b = coerce_bool(b)
      Z3::Ast.new(Z3::LowLevel.mk_iff(a, b))
    end

    def implies(a, b)
      a = coerce_bool(a)
      b = coerce_bool(b)
      Z3::Ast.new(Z3::LowLevel.mk_implies(a, b))
    end

    def sub(*args)
      Z3::Ast.new(Z3::LowLevel.mk_sub(args))
    end

    def mul(*args)
      Z3::Ast.new(Z3::LowLevel.mk_mul(args))
    end

    def bool(name)
      var(name, Z3::Sort.bool)
    end

    def int(name)
      var(name, Z3::Sort.int)
    end

    def real(name)
      var(name, Z3::Sort.real)
    end

    private

    def var(name, sort)
      Z3::Ast.new(
        Z3::LowLevel.mk_const(
          Z3::LowLevel.mk_string_symbol(name),
          sort,
        )
      )
    end
  end
end
