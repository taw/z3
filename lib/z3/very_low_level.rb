# Seriously do not use this directly in your code

require 'ffi'

module Z3::VeryLowLevel
  extend FFI::Library
  ffi_lib "z3"
  # Aliases defined just to make APIs below look nicer
  ast_pointer = :pointer
  ctx_pointer = :pointer
  fixedpoint_pointer = :pointer
  func_decl_pointer = :pointer
  goal_pointer = :pointer
  model_pointer = :pointer
  optimize_pointer = :pointer
  param_descrs_pointer = :pointer
  params_pointer = :pointer
  pattern_pointer = :pointer
  probe_pointer = :pointer
  solver_pointer = :pointer
  sort_pointer = :pointer
  symbol_pointer = :pointer
  tactic_pointer = :pointer
  rcf_num_pointer = :pointer
  stats_pointer = :pointer

  z3_bool = :int

  ### Manually added functions gen_api can't handle [yet]
  callback :error_handler, [ctx_pointer, :int], :void
  attach_function :Z3_get_version, [:pointer, :pointer, :pointer, :pointer], :void
  attach_function :Z3_set_error_handler, [ctx_pointer, :error_handler], :void
  attach_function :Z3_mk_context, [], ctx_pointer
  attach_function :Z3_model_eval, [ctx_pointer, model_pointer, ast_pointer, :bool, :pointer], :int
  attach_function :Z3_model_get_const_decl, [ctx_pointer, model_pointer, :int], func_decl_pointer
  attach_function :Z3_model_get_const_interp, [ctx_pointer, model_pointer, func_decl_pointer], ast_pointer
  attach_function :Z3_get_decl_name, [ctx_pointer, func_decl_pointer], symbol_pointer
  attach_function :Z3_mk_and, [ctx_pointer, :int, :pointer], ast_pointer
  attach_function :Z3_mk_or, [ctx_pointer, :int, :pointer], ast_pointer
  attach_function :Z3_mk_add, [ctx_pointer, :int, :pointer], ast_pointer
  attach_function :Z3_mk_sub, [ctx_pointer, :int, :pointer], ast_pointer
  attach_function :Z3_mk_mul, [ctx_pointer, :int, :pointer], ast_pointer
  attach_function :Z3_mk_distinct, [ctx_pointer, :int, :pointer], ast_pointer

  ### Automatically generated, do not edit that file
  eval open("#{__dir__}/very_low_level_auto.rb").read
end
