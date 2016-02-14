module Z3
  class Context
    attr_reader :_context
    def initialize
      @_context = Z3::Core.Z3_mk_context
    end

    def self.main
      @main ||= new
    end
  end

  class Solver
    def initialize(ctx=Z3::Context.main)
      @ctx = ctx
      @_solver = Z3::Core.Z3_mk_solver(@ctx._context)
    end

    def push
      Z3::Core.Z3_solver_push(@ctx._context, @_solver)
    end

    def pop(n=1)
      Z3::Core.Z3_solver_pop(@ctx._context, @_solver, n)
    end

    def reset
      Z3::Core.Z3_solver_reset(@ctx._context, @_solver)
    end

    def assert(ast)
      Z3::Core.Z3_solver_assert(@ctx._context, @_solver, ast._ast)
    end

    def check
      check_sat_results(Z3::Core.Z3_solver_check(@ctx._context, @_solver))
    end

    private

    def check_sat_results(r)
      case r
      when 1
        :sat
      when 0
        :unknown
      when -1
        :unsat
      else
        raise "Wrong SAT result #{r}"
      end
    end
  end

  class Ast
    attr_reader :_ast
    # Do not use .new directly
    def initialize(_ast, ctx=Z3::Context.main)
      @ctx = ctx
      @_ast = _ast
    end

    def self.true(ctx=Z3::Context.main)
      Z3::Ast.new(Z3::Core.Z3_mk_true(ctx._context), ctx)
    end

    def self.false(ctx=Z3::Context.main)
      Z3::Ast.new(Z3::Core.Z3_mk_false(ctx._context), ctx)
    end

    def self.eq(a, b, ctx=Z3::Context.main)
      Z3::Ast.new(Z3::Core.Z3_mk_eq(ctx._context, a._ast, b._ast), ctx)
    end

    def self.not(a, ctx=Z3::Context.main)
      Z3::Ast.new(Z3::Core.Z3_mk_not(ctx._context, a._ast), ctx)
    end
  end
end

require_relative "z3/core"
