# Seriously do not use this directly in your code
# They unwrap inputs, but don't wrap returns yet

module Z3::LowLevel
  class << self
    # Common API
    def get_version
      a = FFI::MemoryPointer.new(:int)
      b = FFI::MemoryPointer.new(:int)
      c = FFI::MemoryPointer.new(:int)
      d = FFI::MemoryPointer.new(:int)
      Z3::VeryLowLevel.Z3_get_version(a,b,c,d)
      [a.get_uint(0), b.get_uint(0), c.get_uint(0), d.get_uint(0)]
    end

    # Context API
    def mk_context
      Z3::VeryLowLevel.Z3_mk_context
    end

    # Symbol API
    def mk_string_symbol(name)
      Z3::VeryLowLevel.Z3_mk_string_symbol(_ctx_pointer, name)
    end

    # Sort API
    def mk_bool_sort
      Z3::VeryLowLevel.Z3_mk_bool_sort(_ctx_pointer)
    end

    def mk_int_sort
      Z3::VeryLowLevel.Z3_mk_int_sort(_ctx_pointer)
    end

    def mk_real_sort
      Z3::VeryLowLevel.Z3_mk_real_sort(_ctx_pointer)
    end

    def sort_to_string(sort)
      Z3::VeryLowLevel.Z3_sort_to_string(_ctx_pointer, sort._sort)
    end

    # Solver API
    def mk_solver
      Z3::VeryLowLevel.Z3_mk_solver(_ctx_pointer)
    end

    def solver_push(solver)
      Z3::VeryLowLevel.Z3_solver_push(_ctx_pointer, solver._solver)
    end

    def solver_pop(solver, n)
      Z3::VeryLowLevel.Z3_solver_pop(_ctx_pointer, solver._solver, n)
    end

    def solver_reset(solver)
      Z3::VeryLowLevel.Z3_solver_reset(_ctx_pointer, solver._solver)
    end

    def solver_assert(solver, ast)
      Z3::VeryLowLevel.Z3_solver_assert(_ctx_pointer, solver._solver, ast._ast)
    end

    def solver_check(solver)
      Z3::VeryLowLevel.Z3_solver_check(_ctx_pointer, solver._solver)
    end

    # Model API
    def solver_get_model(solver)
      Z3::VeryLowLevel.Z3_solver_get_model(_ctx_pointer, solver._solver)
    end

    def model_get_num_consts(model)
      Z3::VeryLowLevel.Z3_model_get_num_consts(_ctx_pointer, model._model)
    end

    def model_get_num_funcs(model)
      Z3::VeryLowLevel.Z3_model_get_num_funcs(_ctx_pointer, model._model)
    end

    def model_get_num_sorts(model)
      Z3::VeryLowLevel.Z3_model_get_num_sorts(_ctx_pointer, model._model)
    end

    # AST API
    def mk_true
      Z3::VeryLowLevel.Z3_mk_true(_ctx_pointer)
    end

    def mk_false
      Z3::VeryLowLevel.Z3_mk_false(_ctx_pointer)
    end

    def mk_eq(a,b)
      Z3::VeryLowLevel.Z3_mk_eq(_ctx_pointer, a._ast, b._ast)
    end

    def mk_ge(a,b)
      Z3::VeryLowLevel.Z3_mk_ge(_ctx_pointer, a._ast, b._ast)
    end

    def mk_gt(a,b)
      Z3::VeryLowLevel.Z3_mk_gt(_ctx_pointer, a._ast, b._ast)
    end

    def mk_le(a,b)
      Z3::VeryLowLevel.Z3_mk_le(_ctx_pointer, a._ast, b._ast)
    end

    def mk_lt(a,b)
      Z3::VeryLowLevel.Z3_mk_lt(_ctx_pointer, a._ast, b._ast)
    end

    def mk_power(a,b)
      Z3::VeryLowLevel.Z3_mk_power(_ctx_pointer, a._ast, b._ast)
    end

    def mk_not(a)
      Z3::VeryLowLevel.Z3_mk_not(_ctx_pointer, a._ast)
    end

    def mk_const(_symbol, sort)
      Z3::VeryLowLevel.Z3_mk_const(_ctx_pointer, _symbol, sort._sort)
    end

    def mk_and(asts)
      Z3::VeryLowLevel.Z3_mk_and(_ctx_pointer, asts.size, asts_vector(asts))
    end

    def mk_or(asts)
      Z3::VeryLowLevel.Z3_mk_or(_ctx_pointer, asts.size, asts_vector(asts))
    end

    def mk_mul(asts)
      Z3::VeryLowLevel.Z3_mk_mul(_ctx_pointer, asts.size, asts_vector(asts))
    end

    def mk_add(asts)
      Z3::VeryLowLevel.Z3_mk_add(_ctx_pointer, asts.size, asts_vector(asts))
    end

    def mk_sub(asts)
      Z3::VeryLowLevel.Z3_mk_sub(_ctx_pointer, asts.size, asts_vector(asts))
    end

    def mk_distinct(asts)
      Z3::VeryLowLevel.Z3_mk_distinct(_ctx_pointer, asts.size, asts_vector(asts))
    end

    def ast_to_string(ast)
      Z3::VeryLowLevel.Z3_ast_to_string(_ctx_pointer, ast._ast)
    end

    def get_sort(ast)
      Z3::VeryLowLevel.Z3_get_sort(_ctx_pointer, ast._ast)
    end

    def mk_int2real(ast)
      Z3::VeryLowLevel.Z3_mk_int2real(_ctx_pointer, ast._ast)
    end

    def mk_numeral(str, sort)
      Z3::VeryLowLevel.Z3_mk_numeral(_ctx_pointer, str, sort._sort)
    end

    private

    def asts_vector(args)
      raise if args.empty?
      c_args = FFI::MemoryPointer.new(:pointer, args.size)
      c_args.write_array_of_pointer args.map(&:_ast)
      c_args
    end

    def _ctx_pointer
      @_ctx_pointer ||= Z3::Context.instance._context
    end
  end
end
