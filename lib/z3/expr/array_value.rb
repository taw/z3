module Z3
  # A Set is an Array to Bool, and a value of either comes back from Z3 the same way:
  # a chain of `store`s over a `const` base, with the outermost store applied last.
  #
  # Neither Ruby class is the other's superclass, though - a SetExpr reads like a Ruby
  # Set and an ArrayExpr like a Hash, and they're kept apart for the same reason SeqExpr
  # and StringExpr are - so the walk lives here rather than in either of them.
  module ArrayValue
    protected

    # `[default_expr, [[key_expr, value_expr], ...]]`, the stores in the order they were
    # applied, or nil for anything which isn't one of these - a lambda, an `as-array`
    # whose meaning lives in a model rather than in the term, or an array the solver
    # never had to pin down.
    def store_chain
      return nil unless ast_kind == :app
      decl = func_decl
      case decl.name
      when "const"
        # The constant array is an indexed decl - `(as const (Array Int Int))` - and
        # that's what tells it apart from a user function someone named `const`
        [arguments[0], []] if decl.arity == 1 and decl.num_parameters == 1
      when "store"
        return nil unless decl.arity == 3
        inner = arguments[0].store_chain
        return nil unless inner
        default, stores = inner
        [default, stores + [[arguments[1], arguments[2]]]]
      when "map"
        map_chain(decl)
      end
    end

    private

    # `map(f, a, b)` is `f` applied pointwise, and it's how Z3 leaves a set union or
    # difference - its simplifier reduces some of those back to stores and not others.
    # Only the keys one of the arrays writes can differ from the pointwise default, so
    # applying `f` to those and to the defaults says the whole of it. The applications
    # are left as expressions for #value to reduce, the same way it reduces anything
    # else it finds in a chain.
    def map_chain(decl)
      return nil unless decl.num_parameters == 1 and decl.parameter_kind(0) == :func_decl
      chains = arguments.map { |argument| argument.store_chain }
      return nil if chains.any?(&:nil?)
      f = decl.parameter(0)
      keys = chains.flat_map { |_, stores| stores.map(&:first) }.uniq
      entries = keys.map { |key| [key, f[*chains.map { |chain| chain_at(chain, key) }]] }
      [f[*chains.map(&:first)], entries]
    end

    # What a store chain answers for one key - the last store to it, or the default.
    # Z3 hash-conses ASTs, so two numerals of the same value are the same pointer, and
    # AST#eql? comparing pointers is enough to match a key.
    def chain_at(chain, key)
      default, stores = chain
      match = stores.reverse.find { |stored_key, _| stored_key.eql?(key) }
      match ? match[1] : default
    end
  end
end
