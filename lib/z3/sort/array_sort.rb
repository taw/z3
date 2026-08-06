module Z3
  class ArraySort < Sort
    # Z3 has no Set sort of its own, a Set is just Array(X, Bool) - so Array(X, Bool)
    # has to come back as a SetSort, or we'd have two Ruby classes for one Z3 sort.
    # Exactly what SeqSort does with Seq(Char), which is a String.
    #
    # `Sort#==` already ignores the class, so the two sorts always compared equal; it
    # was the *expressions* that didn't. `AST#eql?` compares class as well as pointer
    # while `#hash` is the pointer alone, so one Z3 term arriving as an ArrayExpr from
    # `ArraySort#var` and as a SetExpr from a model was unequal-but-same-hash - the one
    # combination Ruby forbids, and silently wrong as a Hash key.
    #
    # SetSort answers every ArraySort method, so the redirect costs nothing.
    def self.new(key_sort, value_sort)
      return SetSort.new(key_sort) if value_sort == BoolSort.new
      super
    end

    attr_reader :key_sort, :value_sort
    def initialize(key_sort, value_sort)
      @key_sort = key_sort
      @value_sort = value_sort
      super LowLevel.mk_array_sort(key_sort, value_sort)
    end

    def expr_class
      ArrayExpr
    end

    def to_s
      "Array(#{key_sort}, #{value_sort})"
    end

    def inspect
      "ArraySort(#{key_sort}, #{value_sort})"
    end

    # The array which maps every key to the same value. `SetSort#Empty` and `#Full`
    # are this with `false` and `true`, on the SetSort you get instead of an
    # `Array(X, Bool)`.
    def Const(value)
      new(LowLevel.mk_const_array(key_sort, value_sort.cast(value)))
    end

    public_class_method :new
  end
end
