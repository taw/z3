# Seriously do not use this directly in your code
# They unwrap inputs, but don't wrap returns yet

module Z3::LowLevel
  class << self
    def get_version
      a = FFI::MemoryPointer.new(:int)
      b = FFI::MemoryPointer.new(:int)
      c = FFI::MemoryPointer.new(:int)
      d = FFI::MemoryPointer.new(:int)
      Z3::VeryLowLevel.Z3_get_version(a,b,c,d)
      [a.get_uint(0), b.get_uint(0), c.get_uint(0), d.get_uint(0)]
    end

    def set_error_handler(&block)
      Z3::VeryLowLevel.Z3_set_error_handler(_ctx_pointer, block)
    end

    def mk_context
      Z3::VeryLowLevel.Z3_mk_context(Z3::VeryLowLevel.Z3_mk_config)
    end

    def model_eval(model, ast, model_completion)
      rv_ptr = FFI::MemoryPointer.new(:pointer)
      result = Z3::VeryLowLevel.Z3_model_eval(_ctx_pointer, model._model, ast._ast, !!model_completion, rv_ptr)
      if result == 1
        rv_ptr.get_pointer(0)
      else
        raise Z3::Exception, "Evaluation of `#{ast}' failed"
      end
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

    # Should be private

    def unpack_ast_vector(_ast_vector)
      n = Z3::VeryLowLevel.Z3_ast_vector_size(_ctx_pointer, _ast_vector)
      (0...n).map do |i|
        _ast = Z3::VeryLowLevel.Z3_ast_vector_get(_ctx_pointer, _ast_vector, i)
        Z3::Expr.new_from_pointer(_ast)
      end
    end

    def _ctx_pointer
      @_ctx_pointer ||= Z3::Context.instance._context
    end

    private

    def asts_vector(args)
      raise if args.empty?
      c_args = FFI::MemoryPointer.new(:pointer, args.size)
      c_args.write_array_of_pointer args.map(&:_ast)
      c_args
    end
  end
end
