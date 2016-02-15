# Seriously do not use this directly in your code

require 'ffi'

module Z3::VeryLowLevel
  extend FFI::Library
  ffi_lib "z3"
  # Aliases defined just to make APIs below look nicer
  ctx_pointer = :pointer
  solver_pointer = :pointer
  ast_pointer = :pointer
  sort_pointer = :pointer
  symbol = :pointer
  model_pointer = :pointer
  z3_bool = :int

  # Context API
  attach_function :Z3_mk_context, [], ctx_pointer

  # Symbol API
  attach_function :Z3_mk_string_symbol, [ctx_pointer, :string], symbol

  # Sort API
  attach_function :Z3_mk_bool_sort, [ctx_pointer], sort_pointer
  attach_function :Z3_mk_int_sort, [ctx_pointer], sort_pointer
  attach_function :Z3_mk_real_sort, [ctx_pointer], sort_pointer
  attach_function :Z3_sort_to_string, [ctx_pointer, sort_pointer], :string

  # Solver API
  attach_function :Z3_mk_solver, [ctx_pointer], solver_pointer
  attach_function :Z3_solver_push, [ctx_pointer, solver_pointer], :void
  attach_function :Z3_solver_pop, [ctx_pointer, solver_pointer, :int], :void
  attach_function :Z3_solver_reset, [ctx_pointer, solver_pointer], :void
  attach_function :Z3_solver_assert, [ctx_pointer, solver_pointer, ast_pointer], :void
  attach_function :Z3_solver_check, [ctx_pointer, solver_pointer], z3_bool

  # Model API
  attach_function :Z3_solver_get_model, [ctx_pointer, solver_pointer], model_pointer

  # AST API
  attach_function :Z3_mk_true, [ctx_pointer], ast_pointer
  attach_function :Z3_mk_false, [ctx_pointer], ast_pointer
  attach_function :Z3_mk_eq, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
  attach_function :Z3_mk_ge, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
  attach_function :Z3_mk_gt, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
  attach_function :Z3_mk_le, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
  attach_function :Z3_mk_lt, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
  attach_function :Z3_mk_not, [ctx_pointer, ast_pointer], ast_pointer
  attach_function :Z3_mk_const, [ctx_pointer, symbol, sort_pointer], ast_pointer
  attach_function :Z3_mk_and, [ctx_pointer, :int, :pointer], ast_pointer
  attach_function :Z3_mk_or, [ctx_pointer, :int, :pointer], ast_pointer
  attach_function :Z3_mk_add, [ctx_pointer, :int, :pointer], ast_pointer
  attach_function :Z3_mk_sub, [ctx_pointer, :int, :pointer], ast_pointer
  attach_function :Z3_mk_mul, [ctx_pointer, :int, :pointer], ast_pointer
  attach_function :Z3_mk_distinct, [ctx_pointer, :int, :pointer], ast_pointer
  attach_function :Z3_ast_to_string, [ctx_pointer, ast_pointer], :string
  attach_function :Z3_get_sort, [ctx_pointer, ast_pointer], sort_pointer
  attach_function :Z3_mk_int2real, [ctx_pointer, ast_pointer], ast_pointer
  attach_function :Z3_mk_numeral, [ctx_pointer, :string, sort_pointer], ast_pointer
end
