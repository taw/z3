module Z3
  # Seriously do not use this directly in your code
  # They unwrap inputs, but don't wrap returns yet
  module LowLevel
    class << self
      def get_version
        a = FFI::MemoryPointer.new(:int)
        b = FFI::MemoryPointer.new(:int)
        c = FFI::MemoryPointer.new(:int)
        d = FFI::MemoryPointer.new(:int)
        Z3::VeryLowLevel.Z3_get_version(a, b, c, d)
        [a.get_uint(0), b.get_uint(0), c.get_uint(0), d.get_uint(0)]
      end

      def set_error_handler(&block)
        # Z3 keeps the native trampoline FFI builds for this block, and that
        # trampoline dies with the Proc - so we must hold onto it forever
        @error_handler = block
        Z3::VeryLowLevel.Z3_set_error_handler(_ctx_pointer, block)
      end

      def mk_context
        Z3::VeryLowLevel.Z3_mk_context(Z3::VeryLowLevel.Z3_mk_config)
      end

      def model_eval(model, ast, model_completion)
        rv_ptr = FFI::MemoryPointer.new(:pointer)
        result = Z3::VeryLowLevel.Z3_model_eval(_ctx_pointer, model._model, ast._ast, !!model_completion, rv_ptr) & 0xFF
        if result == 1
          rv_ptr.get_pointer(0)
        else
          raise Z3::Exception, "Evaluation of `#{ast}' failed"
        end
      end

      # Takes a raw sort pointer, as Sort.from_pointer needs it before there's any Sort object
      def get_finite_domain_sort_size(_sort)
        size_ptr = FFI::MemoryPointer.new(:uint64)
        found = Z3::VeryLowLevel.Z3_get_finite_domain_sort_size(_ctx_pointer, _sort, size_ptr)
        raise Z3::Exception, "Sort is not a finite domain sort" unless found
        size_ptr.get_uint64(0)
      end

      # Z3 strings are sequences of code points up to 0x2FFFF, and Z3_get_lstring returns
      # them in a half-escaped form: code points 1 to 255 come back as literal bytes,
      # 0 and 256+ as `\u{...}`, and a `\` is escaped as `\u{5c}` only when it would
      # otherwise start an escape. Decoding that gives an ordinary UTF-8 Ruby String.
      def get_string(ast)
        length_ptr = FFI::MemoryPointer.new(:uint)
        _string = Z3::VeryLowLevel.Z3_get_lstring(_ctx_pointer, ast._ast, length_ptr)
        raw = _string.read_string(length_ptr.get_uint(0))
        raw.scan(/\\u\{([0-9a-fA-F]+)\}|(.)/m).map { |escape, byte|
          escape ? escape.to_i(16) : byte.ord
        }.pack("U*")
      end

      # The other direction. Z3 decodes escapes in what we pass it, so every code point
      # that get_string would escape has to go back in escaped - including `\` itself,
      # or a string containing the text `\u{41}` would come back as `A`.
      def mk_string(str)
        escaped = str.each_codepoint.map { |code_point|
          if (1..255).cover?(code_point) and code_point != 0x5c
            code_point.chr("BINARY")
          else
            "\\u{%x}" % code_point
          end
        }.join
        Z3::VeryLowLevel.Z3_mk_string(_ctx_pointer, escaped)
      end

      # Z3 symbols are either strings or integers
      def mk_symbol(name)
        if name.is_a?(Integer)
          mk_int_symbol(name)
        else
          mk_string_symbol(name.to_s)
        end
      end

      # The other direction. Takes a raw symbol pointer, as symbols are passed around
      # unwrapped - which kind it is has to be asked before it can be read.
      def symbol_value(_symbol)
        if get_symbol_kind(_symbol) == 0
          get_symbol_int(_symbol)
        else
          get_symbol_string(_symbol)
        end
      end

      def mk_and(asts)
        Z3::VeryLowLevel.Z3_mk_and(_ctx_pointer, asts.size, asts_vector(asts))
      end

      def mk_or(asts)
        Z3::VeryLowLevel.Z3_mk_or(_ctx_pointer, asts.size, asts_vector(asts))
      end

      def mk_atmost(asts, k)
        Z3::VeryLowLevel.Z3_mk_atmost(_ctx_pointer, asts.size, asts_vector(asts), k)
      end

      def mk_atleast(asts, k)
        Z3::VeryLowLevel.Z3_mk_atleast(_ctx_pointer, asts.size, asts_vector(asts), k)
      end

      def mk_pbeq(asts, coeffs, k)
        Z3::VeryLowLevel.Z3_mk_pbeq(_ctx_pointer, asts.size, asts_vector(asts), ints_vector(coeffs), k)
      end

      def mk_seq_concat(asts)
        Z3::VeryLowLevel.Z3_mk_seq_concat(_ctx_pointer, asts.size, asts_vector(asts))
      end

      def mk_re_concat(asts)
        Z3::VeryLowLevel.Z3_mk_re_concat(_ctx_pointer, asts.size, asts_vector(asts))
      end

      def mk_re_union(asts)
        Z3::VeryLowLevel.Z3_mk_re_union(_ctx_pointer, asts.size, asts_vector(asts))
      end

      def mk_re_intersect(asts)
        Z3::VeryLowLevel.Z3_mk_re_intersect(_ctx_pointer, asts.size, asts_vector(asts))
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

      def mk_set_union(asts)
        Z3::VeryLowLevel.Z3_mk_set_union(_ctx_pointer, asts.size, asts_vector(asts))
      end

      def mk_set_intersect(asts)
        Z3::VeryLowLevel.Z3_mk_set_intersect(_ctx_pointer, asts.size, asts_vector(asts))
      end

      def optimize_check(optimize, asts)
        Z3::VeryLowLevel.Z3_optimize_check(_ctx_pointer, optimize._optimize, asts.size, asts_vector(asts))
      end

      def solver_check_assumptions(solver, asts)
        Z3::VeryLowLevel.Z3_solver_check_assumptions(_ctx_pointer, solver._solver, asts.size, asts_vector(asts))
      end

      # `from` and `to` are parallel, and Z3 requires them to be the same length
      def substitute(ast, from_asts, to_asts)
        Z3::VeryLowLevel.Z3_substitute(_ctx_pointer, ast._ast, from_asts.size, asts_vector(from_asts), asts_vector(to_asts))
      end

      def mk_func_decl(symbol, domain_sorts, range_sort)
        Z3::VeryLowLevel.Z3_mk_func_decl(_ctx_pointer, symbol, domain_sorts.size, asts_vector(domain_sorts), range_sort._ast)
      end

      # Takes a plain String prefix rather than a symbol, and Z3 appends a number
      def mk_fresh_func_decl(prefix, domain_sorts, range_sort)
        Z3::VeryLowLevel.Z3_mk_fresh_func_decl(_ctx_pointer, prefix, domain_sorts.size, asts_vector(domain_sorts), range_sort._ast)
      end

      def mk_app(func_decl, args)
        Z3::VeryLowLevel.Z3_mk_app(_ctx_pointer, func_decl._ast, args.size, asts_vector(args))
      end

      # Z3 fills in a constructor and a tester func decl for every value. Both are
      # recoverable from the sort afterwards - get_datatype_sort_constructor and
      # friends - so the arrays are thrown away, but they still have to be allocated
      # rather than passed as NULL, which segfaults.
      def mk_enumeration_sort(symbol, value_symbols)
        n = value_symbols.size
        _names = FFI::MemoryPointer.new(:pointer, n)
        _names.write_array_of_pointer(value_symbols)
        _consts = FFI::MemoryPointer.new(:pointer, n)
        _testers = FFI::MemoryPointer.new(:pointer, n)
        Z3::VeryLowLevel.Z3_mk_enumeration_sort(_ctx_pointer, symbol, n, _names, _consts, _testers)
      end

      # Weight is a hint to the instantiation engine rather than part of what the
      # formula means, but a bad one turns a decidable problem into `:unknown` - the
      # same unsat query answers at weight 20 and gives up at weight 50 - so it's
      # pinned to 1. That's what parsing the same formula out of SMT-LIB gives, and
      # it's the one value Z3 prints without an annotation. (The C header says to pass
      # 0, and then disagrees with itself in both of those places.) Patterns are the
      # other half of the same knob, and left out for the same reason.
      def mk_forall_const(bound, body)
        Z3::VeryLowLevel.Z3_mk_forall_const(_ctx_pointer, 1, bound.size, asts_vector(bound), 0, nil, body._ast)
      end

      def mk_exists_const(bound, body)
        Z3::VeryLowLevel.Z3_mk_exists_const(_ctx_pointer, 1, bound.size, asts_vector(bound), 0, nil, body._ast)
      end

      # No weight and no patterns on this one - a lambda is a value, not something the
      # solver has to decide when to instantiate
      def mk_lambda_const(bound, body)
        Z3::VeryLowLevel.Z3_mk_lambda_const(_ctx_pointer, bound.size, asts_vector(bound), body._ast)
      end

      # The only tactic combinator taking an array rather than two tactics
      def tactic_par_or(tactics)
        _tactics = FFI::MemoryPointer.new(:pointer, tactics.size)
        _tactics.write_array_of_pointer(tactics.map(&:_tactic))
        Z3::VeryLowLevel.Z3_tactic_par_or(_ctx_pointer, tactics.size, _tactics)
      end

      # Should be private

      # Every AST_VECTOR parameter in the C API is an `_in` - the ones which act like
      # out parameters are vectors the caller allocates and Z3 fills in or empties.
      # So they only ever need to live for the length of one call, and there's no
      # reason for a Ruby class: build them here, read the results back with
      # #unpack_ast_vector, and let the ensure release them.
      def with_ast_vectors(*arrays)
        _ast_vectors = []
        arrays.each do |asts|
          # Pushed onto the list before anything can raise, so a bad `asts` still frees
          _ast_vector = mk_ast_vector
          ast_vector_inc_ref(_ast_vector)
          _ast_vectors << _ast_vector
          asts.each { |ast| ast_vector_push(_ast_vector, ast) }
        end
        yield(*_ast_vectors)
      ensure
        _ast_vectors.each { |_ast_vector| ast_vector_dec_ref(_ast_vector) }
      end

      def unpack_ast_vector(_ast_vector)
        ast_vector_size(_ast_vector).times.map do |i|
          _ast = ast_vector_get(_ast_vector, i)
          Expr.new_from_pointer(_ast)
        end
      end

      # What a model says a function does: the argument lists it had to pin down, and
      # a fallback for everything else. Ruby's Hash default is exactly Z3's `else`
      # branch, so a plain Hash answers for arguments with no entry of their own.
      # Keys are argument lists whatever the arity, so a unary function is `[[2]]`
      # rather than `[2]` - one shape for every function.
      def unpack_func_interp(_func_interp)
        func_interp_inc_ref(_func_interp)
        interp = {}
        begin
          func_interp_get_num_entries(_func_interp).times do |i|
            _entry = func_interp_get_entry(_func_interp, i)
            func_entry_inc_ref(_entry)
            begin
              args = func_entry_get_num_args(_entry).times.map do |j|
                Expr.new_from_pointer(func_entry_get_arg(_entry, j))
              end
              interp[args] = Expr.new_from_pointer(func_entry_get_value(_entry))
            ensure
              func_entry_dec_ref(_entry)
            end
          end
          interp.default = Expr.new_from_pointer(func_interp_get_else(_func_interp))
        ensure
          func_interp_dec_ref(_func_interp)
        end
        interp
      end

      def unpack_statistics(_stats)
        stats = {}
        stats_size(_stats).times.map do |i|
          key = stats_get_key(_stats, i)
          if stats_is_double(_stats, i)
            val = stats_get_double_value(_stats, i)
          elsif stats_is_uint(_stats, i)
            val = stats_get_uint_value(_stats, i)
          else
            raise Z3::Exception, "Stat is neither double nor uint, that's not supposed to happen"
          end
          raise Z3::Exception, "Key #{key} duplicated in stats" if stats.has_key?(key)
          stats[key] = val
        end
        stats
      end

      # These take raw pointers, as finalizers must not hold onto the wrapper object
      def inc_ref_pointer(kind, pointer)
        Z3::VeryLowLevel.public_send("Z3_#{kind}_inc_ref", _ctx_pointer, pointer)
      end

      def dec_ref_pointer(kind, pointer)
        Z3::VeryLowLevel.public_send("Z3_#{kind}_dec_ref", _ctx_pointer, pointer)
      end

      def _ctx_pointer
        @_ctx_pointer ||= Z3::Context.instance._context
      end

      private

      def asts_vector(args)
        # raise if args.empty?
        c_args = FFI::MemoryPointer.new(:pointer, args.size)
        c_args.write_array_of_pointer args.map(&:_ast)
        c_args
      end

      def ints_vector(args)
        c_args = FFI::MemoryPointer.new(:int, args.size)
        c_args.write_array_of_int args
        c_args
      end
    end
  end
end
