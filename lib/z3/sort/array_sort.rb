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

    public_class_method :new
  end
end
