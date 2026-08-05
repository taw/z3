module Z3
  class ArrayExpr < Expr
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

    def select(key)
      sort.value_sort.new LowLevel.mk_select(self, key_sort.cast(key))
    end

    def [](key)
      select(key)
    end

    # The array's fallback - what it answers for keys nothing has stored to. It's the
    # same idea as the Hash default a model reports for a function, and #store leaves
    # it alone, so `ArraySort#Const(0).store(7, 1).default` is still 0.
    def default
      value_sort.new(LowLevel.mk_array_default(self))
    end
  end
end
