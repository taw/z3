module Z3
  class ArrayExpr < Expr
    include ArrayValue
    public_class_method :new

    def key_sort
      sort.key_sort
    end

    def value_sort
      sort.value_sort
    end

    def store(key, value)
      sort.new LowLevel.mk_store(self, key_sort.cast(key), value_sort.cast(value))
    end

    # Z3 calls this `select`, and that name is deliberately not exposed - Ruby's
    # `select` filters a collection, which is the one thing this doesn't do
    def [](key)
      sort.value_sort.new LowLevel.mk_select(self, key_sort.cast(key))
    end

    # The array's fallback - what it answers for keys nothing has stored to. It's the
    # same idea as the Hash default a model reports for a function, and #store leaves
    # it alone, so `ArraySort#Const(0).store(7, 1).default` is still 0.
    def default
      value_sort.new(LowLevel.mk_array_default(self))
    end

    # A Ruby Hash out of an array value, with #value called on every key and value.
    # An array is a total map, so the entries alone can't say what it is - Ruby's Hash
    # default holds #default, which is the answer for every key not listed. That's the
    # same shape `Model#func_interp` gives a function, and for the same reason.
    #
    #   ArraySort.new(IntSort.new, IntSort.new).Const(0).store(2, 7).value
    #   # => {2 => 7}, with a default of 0, so [5] is 0
    #
    # This reads the term as it stands rather than canonicalising it, so a store of the
    # default value is still an entry - it just answers the same as the default would.
    # Raises for anything which isn't a store chain over a const, a lambda especially.
    def value
      chain = store_chain || simplify.store_chain
      raise Z3::Exception, "Can't convert expression #{self} into Hash" unless chain
      default, stores = chain
      stores.each_with_object(Hash.new(default.value)) do |(key, val), hash|
        hash[key.value] = val.value
      end
    end
  end
end
