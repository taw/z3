class Z3::Ast
  attr_reader :_ast, :_ctx
  # Do not use .new directly
  def initialize(_ast, ctx=Z3::Context.main)
    @_ctx = ctx
    @_ast = _ast
  end

  def ~
    Z3::Ast.not(self, ctx: @_ctx)
  end

  def |(b)
    raise "Not same context" unless @_ctx == b._ctx
    Z3::Ast.or(self, b, ctx: @_ctx)
  end

  def &(b)
    raise "Not same context" unless @_ctx == b._ctx
    Z3::Ast.and(self, b, ctx: @_ctx)
  end

  def +(b)
    raise "Not same context" unless @_ctx == b._ctx
    Z3::Ast.add(self, b, ctx: @_ctx)
  end

  def *(b)
    raise "Not same context" unless @_ctx == b._ctx
    Z3::Ast.mul(self, b, ctx: @_ctx)
  end

  def -(b)
    raise "Not same context" unless @_ctx == b._ctx
    Z3::Ast.sub(self, b, ctx: @_ctx)
  end

  def ==(b)
    raise "Not same context" unless @_ctx == b._ctx
    Z3::Ast.eq(self, b, ctx: @_ctx)
  end

  def !=(b)
    raise "Not same context" unless @_ctx == b._ctx
    Z3::Ast.distinct(self, b, ctx: @_ctx)
  end

  def <=(b)
    raise "Not same context" unless @_ctx == b._ctx
    Z3::Ast.le(self, b, ctx: @_ctx)
  end

  def <(b)
    raise "Not same context" unless @_ctx == b._ctx
    Z3::Ast.lt(self, b, ctx: @_ctx)
  end

  def >=(b)
    raise "Not same context" unless @_ctx == b._ctx
    Z3::Ast.ge(self, b, ctx: @_ctx)
  end

  def >(b)
    raise "Not same context" unless @_ctx == b._ctx
    Z3::Ast.gt(self, b, ctx: @_ctx)
  end

  class <<self
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
