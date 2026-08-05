module Z3
  class ArraySort < Sort
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
    # are this with `false` and `true` - a Set is an Array with a Bool value sort.
    def Const(value)
      new(LowLevel.mk_const_array(key_sort, value_sort.cast(value)))
    end

    public_class_method :new
  end
end
