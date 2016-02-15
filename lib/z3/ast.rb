class Z3::Ast
  attr_reader :_ast
  # Do not use .new directly
  def initialize(_ast)
    @_ast = _ast
  end

  def sort
    Z3::Sort.new(
      Z3::Core.Z3_get_sort(Z3::Context._context, @_ast)
    )
  end

  def to_s
    Z3::Core.Z3_ast_to_string(Z3::Context._context, @_ast)
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
    raise Z3::Exception, "Type mismatch" unless sort == Z3::Sort.int
    Z3::Ast.new(
      Z3::Core.Z3_mk_int2real(Z3::Context._context, @_ast)
    )
  end

  class <<self
    def from_const(value, sort)
      case sort
      when Z3::Sort.bool
        raise Z3::Exception, "Can't convert #{value.class} to Real" unless value == true or value == false
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
          Z3::Ast.new(Z3::Core.Z3_mk_numeral(Z3::Context._context, value.to_s, Z3::Sort.real._sort))
        else
          Z3::Ast.new(Z3::Core.Z3_mk_numeral(Z3::Context._context, value.to_s, sort._sort))
        end
      when Z3::Sort.real
        raise Z3::Exception, "Can't convert #{value.class} to Real" unless value.is_a?(Numeric)
        Z3::Ast.new(Z3::Core.Z3_mk_numeral(Z3::Context._context, value.to_s, sort._sort))
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
      Z3::Ast.new(Z3::Core.Z3_mk_true(Z3::Context._context))
    end

    def false
      Z3::Ast.new(Z3::Core.Z3_mk_false(Z3::Context._context))
    end

    def eq(a, b)
      Z3::Ast.new(Z3::Core.Z3_mk_eq(Z3::Context._context, a._ast, b._ast))
    end

    def ge(a, b)
      Z3::Ast.new(Z3::Core.Z3_mk_ge(Z3::Context._context, a._ast, b._ast))
    end

    def gt(a, b)
      Z3::Ast.new(Z3::Core.Z3_mk_gt(Z3::Context._context, a._ast, b._ast))
    end

    def le(a, b)
      Z3::Ast.new(Z3::Core.Z3_mk_le(Z3::Context._context, a._ast, b._ast))
    end

    def lt(a, b)
      Z3::Ast.new(Z3::Core.Z3_mk_lt(Z3::Context._context, a._ast, b._ast))
    end

    def not(a)
      Z3::Ast.new(Z3::Core.Z3_mk_not(Z3::Context._context, a._ast))
    end

    def distinct(*args)
      ast_vararg_operator(:Z3_mk_distinct, args)
    end

    def and(*args)
      ast_vararg_operator(:Z3_mk_and, args)
    end

    def or(*args)
      ast_vararg_operator(:Z3_mk_or, args)
    end

    def add(*args)
      ast_vararg_operator(:Z3_mk_add, args)
    end

    def sub(*args)
      ast_vararg_operator(:Z3_mk_sub, args)
    end

    def mul(*args)
      ast_vararg_operator(:Z3_mk_mul, args)
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

    def ast_vararg_operator(sym, args)
      raise if args.empty?
      c_args = FFI::MemoryPointer.new(:pointer, args.size)
      c_args.write_array_of_pointer args.map(&:_ast)
      Z3::Ast.new(Z3::Core.send(sym, Z3::Context._context, args.size, c_args))
    end

    def var(name, sort)
      Z3::Ast.new(
        Z3::Core.Z3_mk_const(
          Z3::Context._context,
          Z3::Core.Z3_mk_string_symbol(Z3::Context._context, name),
          sort._sort,
        )
      )
    end
  end
end
