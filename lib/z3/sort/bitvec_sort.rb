module Z3
  class BitvecSort < Sort
    def initialize(n)
      super LowLevel.mk_bv_sort(n)
    end

    def value_class
      BitvecValue
    end

    def size
      LowLevel.get_bv_sort_size(self)
    end

    def to_s
      "BitVec(#{size})"
    end

    def inspect
      "BitVecSort(#{size})"
    end

    public_class_method :new
  end
end
