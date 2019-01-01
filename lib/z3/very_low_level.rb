# Seriously do not use this directly in your code
require "ffi"

module Z3
  module VeryLowLevel
    extend FFI::Library
    ffi_lib ["z3", "libz3.so.4.8"]

    class << self
      # Aliases defined just to make APIs below look nicer
      def attach_function(name, arg_types, return_type)
        arg_types = arg_types.map { |t| map_type(t) }
        return_type = map_type(return_type)
        super(name, arg_types, return_type)
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
    attach_function :Z3_mk_and, [:ctx_pointer, :int, :pointer], :ast_pointer
    attach_function :Z3_mk_or, [:ctx_pointer, :int, :pointer], :ast_pointer
    attach_function :Z3_mk_add, [:ctx_pointer, :int, :pointer], :ast_pointer
    attach_function :Z3_mk_sub, [:ctx_pointer, :int, :pointer], :ast_pointer
    attach_function :Z3_mk_mul, [:ctx_pointer, :int, :pointer], :ast_pointer
    attach_function :Z3_mk_set_union, [:ctx_pointer, :int, :pointer], :ast_pointer
    attach_function :Z3_mk_set_intersect, [:ctx_pointer, :int, :pointer], :ast_pointer
    attach_function :Z3_mk_distinct, [:ctx_pointer, :int, :pointer], :ast_pointer
    attach_function :Z3_optimize_check, [:ctx_pointer, :optimize_pointer, :int, :pointer], :int
  end
end
