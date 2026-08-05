# Seriously do not use this directly in your code
require "ffi"

module Z3
  module VeryLowLevel
    extend FFI::Library
    ffi_lib ["libz3.so.4.8", "libz3.so", "z3", "libz3"]

    class << self
      # Aliases defined just to make APIs below look nicer
      def attach_function(name, arg_types, return_type)
        arg_types = arg_types.map { |t| map_type(t) }
        return_type = map_type(return_type)
        super(name, arg_types, return_type)
      rescue FFI::NotFoundError
        define_singleton_method(name) do |*args|
          raise Z3::Exception, "Could not find #{name} in the Z3 library. It is likely that the Z3 library has wrong version."
        end
      end

      def map_type(t)
        if t.to_s =~ /\A(.*)_pointer\z/
          :pointer
        else
          t
        end
      end
    end

    ### Manually added functions gen_api can't handle [yet]
    # callback :error_handler, [:ctx_pointer, :int], :void
    callback :error_handler, [:pointer, :int], :void
    attach_function :Z3_get_version, [:pointer, :pointer, :pointer, :pointer], :void
    attach_function :Z3_set_error_handler, [:ctx_pointer, :error_handler], :void
    attach_function :Z3_mk_context, [:config_pointer], :ctx_pointer
    attach_function :Z3_model_eval, [:ctx_pointer, :model_pointer, :ast_pointer, :bool, :pointer], :int
    attach_function :Z3_get_finite_domain_sort_size, [:ctx_pointer, :sort_pointer, :pointer], :bool
    # Returns the length in an out param, and the string can contain \0, so it's :pointer not :string
    attach_function :Z3_get_lstring, [:ctx_pointer, :ast_pointer, :pointer], :pointer
    attach_function :Z3_mk_and, [:ctx_pointer, :int, :pointer], :ast_pointer
    attach_function :Z3_mk_seq_concat, [:ctx_pointer, :int, :pointer], :ast_pointer
    attach_function :Z3_mk_re_concat, [:ctx_pointer, :int, :pointer], :ast_pointer
    attach_function :Z3_mk_re_union, [:ctx_pointer, :int, :pointer], :ast_pointer
    attach_function :Z3_mk_re_intersect, [:ctx_pointer, :int, :pointer], :ast_pointer
    attach_function :Z3_mk_string, [:ctx_pointer, :string], :ast_pointer
    attach_function :Z3_mk_or, [:ctx_pointer, :int, :pointer], :ast_pointer
    attach_function :Z3_mk_atmost, [:ctx_pointer, :int, :pointer, :int], :ast_pointer
    attach_function :Z3_mk_atleast, [:ctx_pointer, :int, :pointer, :int], :ast_pointer
    attach_function :Z3_mk_pbeq, [:ctx_pointer, :int, :pointer, :pointer, :int], :ast_pointer
    attach_function :Z3_mk_add, [:ctx_pointer, :int, :pointer], :ast_pointer
    attach_function :Z3_mk_sub, [:ctx_pointer, :int, :pointer], :ast_pointer
    attach_function :Z3_mk_mul, [:ctx_pointer, :int, :pointer], :ast_pointer
    attach_function :Z3_mk_set_union, [:ctx_pointer, :int, :pointer], :ast_pointer
    attach_function :Z3_mk_set_intersect, [:ctx_pointer, :int, :pointer], :ast_pointer
    attach_function :Z3_mk_distinct, [:ctx_pointer, :int, :pointer], :ast_pointer
    attach_function :Z3_optimize_check, [:ctx_pointer, :optimize_pointer, :int, :pointer], :int
    attach_function :Z3_solver_check_assumptions, [:ctx_pointer, :solver_pointer, :int, :pointer], :int
    attach_function :Z3_substitute, [:ctx_pointer, :ast_pointer, :int, :pointer, :pointer], :ast_pointer
    attach_function :Z3_mk_func_decl, [:ctx_pointer, :symbol_pointer, :int, :pointer, :sort_pointer], :func_decl_pointer
    attach_function :Z3_mk_app, [:ctx_pointer, :func_decl_pointer, :int, :pointer], :ast_pointer
    attach_function :Z3_mk_fresh_func_decl, [:ctx_pointer, :string, :int, :pointer, :sort_pointer], :func_decl_pointer
    # The last two are out params - Z3 segfaults rather than skipping them if either is NULL
    attach_function :Z3_mk_enumeration_sort, [:ctx_pointer, :symbol_pointer, :int, :pointer, :pointer, :pointer], :sort_pointer
  end
end
