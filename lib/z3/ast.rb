class Z3::Ast
  attr_reader :_ast, :ctx
  # Do not use .new directly
  def initialize(_ast, ctx=Z3::Context.main)
    @ctx = ctx
    @_ast = _ast
  end

  def sort
    Z3::Sort.new(
      Z3::Core.Z3_get_sort(@ctx._context, @_ast),
      ctx: @ctx
    )
  end

  def to_s
    Z3::Core.Z3_ast_to_string(@ctx._context, @_ast)
  end

  def inspect
    "Z3::Ast<#{to_s} :: #{sort.to_s}>"
  end

  def ~
    Z3::Ast.not(self, ctx: @ctx)
  end

  def |(b)
    raise Z3::Exception, "Not same context" unless @ctx == b.ctx
    raise Z3::Exception, "Type mismatch" unless sort == b.sort
    Z3::Ast.or(self, b, ctx: @ctx)
  end

  def &(b)
    raise Z3::Exception, "Not same context" unless @ctx == b.ctx
    raise Z3::Exception, "Type mismatch" unless sort == b.sort
    Z3::Ast.and(self, b, ctx: @ctx)
  end

  def +(b)
    raise Z3::Exception, "Not same context" unless @ctx == b.ctx
    raise Z3::Exception, "Type mismatch" unless sort == b.sort
    Z3::Ast.add(self, b, ctx: @ctx)
  end

  def *(b)
    raise Z3::Exception, "Not same context" unless @ctx == b.ctx
    raise Z3::Exception, "Type mismatch" unless sort == b.sort
    Z3::Ast.mul(self, b, ctx: @ctx)
  end

  def -(b)
    raise Z3::Exception, "Not same context" unless @ctx == b.ctx
    raise Z3::Exception, "Type mismatch" unless sort == b.sort
    Z3::Ast.sub(self, b, ctx: @ctx)
  end

  def ==(b)
    unless b.is_a?(Z3::Ast)
      b = Z3::Ast.from_const(b, sort, ctx: @ctx)
    end
    if sort != b.sort
      a, b = Z3::Ast.coerce_to_same_sort(self, b)
    else
      a = self
    end
    raise Z3::Exception, "Not same context" unless @ctx == b.ctx
    Z3::Ast.eq(self, b, ctx: @ctx)
  end

  def !=(b)
    raise Z3::Exception, "Not same context" unless @ctx == b.ctx
    raise Z3::Exception, "Type mismatch" unless sort == b.sort
    Z3::Ast.distinct(self, b, ctx: @ctx)
  end

  def <=(b)
    raise Z3::Exception, "Not same context" unless @ctx == b.ctx
    raise Z3::Exception, "Type mismatch" unless sort == b.sort
    Z3::Ast.le(self, b, ctx: @ctx)
  end

  def <(b)
    raise Z3::Exception, "Not same context" unless @ctx == b.ctx
    raise Z3::Exception, "Type mismatch" unless sort == b.sort
    Z3::Ast.lt(self, b, ctx: @ctx)
  end

  def >=(b)
    raise Z3::Exception, "Not same context" unless @ctx == b.ctx
    raise Z3::Exception, "Type mismatch" unless sort == b.sort
    Z3::Ast.ge(self, b, ctx: @ctx)
  end

  def >(b)
    raise Z3::Exception, "Not same context" unless @ctx == b.ctx
    raise Z3::Exception, "Type mismatch" unless sort == b.sort
    Z3::Ast.gt(self, b, ctx: @ctx)
  end

  def coerce(other)
    require 'pry'; binding.pry
  end

  def int_to_real
    raise Z3::Exception, "Type mismatch" unless sort == Z3::Sort.int
    Z3::Ast.new(
      Z3::Core.Z3_mk_int2real(@ctx._context, @_ast),
      @ctx
    )
  end

  class <<self
    def from_const(value, sort, ctx: Z3::Context.main)
      case sort
      when Z3::Sort.bool
        raise Z3::Exception, "Can't convert #{value.class} to Real" unless value == true or value == false
        if value
          Z3::Ast.true(ctx: ctx)
        else
          Z3::Ast.false(ctx: ctx)
        end
      when Z3::Sort.int
        # (int_var == 2.4) gets changed to
        # ((int_to_real int_var) == (mknumeral 2.4))
        raise Z3::Exception, "Can't convert #{value.class} to Real" unless value.is_a?(Numeric)
        if value.is_a?(Float)
          Z3::Ast.new(Z3::Core.Z3_mk_numeral(ctx._context, value.to_s, Z3::Sort.real(ctx: ctx)._sort), ctx)
        else
          Z3::Ast.new(Z3::Core.Z3_mk_numeral(ctx._context, value.to_s, sort._sort), ctx)
        end
      when Z3::Sort.real
        raise Z3::Exception, "Can't convert #{value.class} to Real" unless value.is_a?(Numeric)
        Z3::Ast.new(Z3::Core.Z3_mk_numeral(ctx._context, value.to_s, sort._sort), ctx)
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

    def true(ctx: Z3::Context.main)
      Z3::Ast.new(Z3::Core.Z3_mk_true(ctx._context), ctx)
    end

    def false(ctx: Z3::Context.main)
      Z3::Ast.new(Z3::Core.Z3_mk_false(ctx._context), ctx)
    end

    def eq(a, b, ctx: Z3::Context.main)
      Z3::Ast.new(Z3::Core.Z3_mk_eq(ctx._context, a._ast, b._ast), ctx)
    end

    def ge(a, b, ctx: Z3::Context.main)
      Z3::Ast.new(Z3::Core.Z3_mk_ge(ctx._context, a._ast, b._ast), ctx)
    end

    def gt(a, b, ctx: Z3::Context.main)
      Z3::Ast.new(Z3::Core.Z3_mk_gt(ctx._context, a._ast, b._ast), ctx)
    end

    def le(a, b, ctx: Z3::Context.main)
      Z3::Ast.new(Z3::Core.Z3_mk_le(ctx._context, a._ast, b._ast), ctx)
    end

    def lt(a, b, ctx: Z3::Context.main)
      Z3::Ast.new(Z3::Core.Z3_mk_lt(ctx._context, a._ast, b._ast), ctx)
    end

    def not(a, ctx: Z3::Context.main)
      Z3::Ast.new(Z3::Core.Z3_mk_not(ctx._context, a._ast), ctx)
    end

    def distinct(*args, ctx: Z3::Context.main)
      ast_vararg_operator(:Z3_mk_distinct, args, ctx)
    end

    def and(*args, ctx: Z3::Context.main)
      ast_vararg_operator(:Z3_mk_and, args, ctx)
    end

    def or(*args, ctx: Z3::Context.main)
      ast_vararg_operator(:Z3_mk_or, args, ctx)
    end

    def add(*args, ctx: Z3::Context.main)
      ast_vararg_operator(:Z3_mk_add, args, ctx)
    end

    def sub(*args, ctx: Z3::Context.main)
      ast_vararg_operator(:Z3_mk_sub, args, ctx)
    end

    def mul(*args, ctx: Z3::Context.main)
      ast_vararg_operator(:Z3_mk_mul, args, ctx)
    end

    def bool(name, ctx: Z3::Context.main)
      var(name, Z3::Sort.bool(ctx: ctx), ctx)
    end

    def int(name, ctx: Z3::Context.main)
      var(name, Z3::Sort.int(ctx: ctx), ctx)
    end

    def real(name, ctx: Z3::Context.main)
      var(name, Z3::Sort.real(ctx: ctx), ctx)
    end

    private

    def ast_vararg_operator(sym, args, ctx)
      raise if args.empty?
      c_args = FFI::MemoryPointer.new(:pointer, args.size)
      c_args.write_array_of_pointer args.map(&:_ast)
      Z3::Ast.new(Z3::Core.send(sym, ctx._context, args.size, c_args), ctx)
    end

    def var(name, sort, ctx)
      Z3::Ast.new(
        Z3::Core.Z3_mk_const(
          ctx._context,
          Z3::Core.Z3_mk_string_symbol(ctx._context, name),
          sort._sort,
        ),
        ctx
      )
    end
  end
end
