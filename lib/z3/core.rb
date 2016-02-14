require 'ffi'

module Z3::Core
  extend FFI::Library
  ffi_lib "z3"
  # Aliases defined just to make APIs below look nicer
  ctx_pointer = :pointer
  solver_pointer = :pointer
  ast_pointer = :pointer
  z3_bool = :int
  # Context API
  attach_function :Z3_mk_context, [], ctx_pointer
  # Solver API
  attach_function :Z3_mk_solver, [ctx_pointer], solver_pointer
  attach_function :Z3_solver_push, [ctx_pointer, solver_pointer], :void
  attach_function :Z3_solver_pop, [ctx_pointer, solver_pointer, :int], :void
  attach_function :Z3_solver_reset, [ctx_pointer, solver_pointer], :void
  attach_function :Z3_solver_assert, [ctx_pointer, solver_pointer, ast_pointer], :void
  attach_function :Z3_solver_check, [ctx_pointer, solver_pointer], z3_bool
  # AST API
  attach_function :Z3_mk_true, [ctx_pointer], ast_pointer
  attach_function :Z3_mk_false, [ctx_pointer], ast_pointer
  attach_function :Z3_mk_eq, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
  attach_function :Z3_mk_not, [ctx_pointer, ast_pointer], ast_pointer
end
