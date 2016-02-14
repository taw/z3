class Z3::Ast
  attr_reader :_ast
  # Do not use .new directly
  def initialize(_ast, ctx=Z3::Context.main)
    @ctx = ctx
    @_ast = _ast
  end

  class <<self
    def true(ctx: Z3::Context.main)
      Z3::Ast.new(Z3::Core.Z3_mk_true(ctx._context), ctx: ctx)
    end

    def false(ctx: Z3::Context.main)
      Z3::Ast.new(Z3::Core.Z3_mk_false(ctx._context), ctx: ctx)
    end

    def eq(a, b, ctx: Z3::Context.main)
      Z3::Ast.new(Z3::Core.Z3_mk_eq(ctx._context, a._ast, b._ast), ctx: ctx)
    end

    def not(a, ctx: Z3::Context.main)
      Z3::Ast.new(Z3::Core.Z3_mk_not(ctx._context, a._ast), ctx: ctx)
    end

    def and(*args, ctx: Z3::Context.main)
      raise if args.empty?
      c_args = FFI::MemoryPointer.new(:pointer, args.size)
      c_args.write_array_of_pointer args.map(&:_ast)
      Z3::Ast.new(Z3::Core.Z3_mk_and(ctx._context, args.size, c_args), ctx: ctx)
    end

    def or(*args, ctx: Z3::Context.main)
      raise if args.empty?
      c_args = FFI::MemoryPointer.new(:pointer, args.size)
      c_args.write_array_of_pointer args.map(&:_ast)
      Z3::Ast.new(Z3::Core.Z3_mk_or(ctx._context, args.size, c_args), ctx: ctx)
    end

    def bool(name, ctx: Z3::Context.main)
      Z3::Ast.new(
        Z3::Core.Z3_mk_const(
          ctx._context,
          Z3::Core.Z3_mk_string_symbol(ctx._context, name),
          Z3::Sort.bool(ctx: ctx)._sort,
        ),
        ctx: ctx
      )
    end
  end
end
