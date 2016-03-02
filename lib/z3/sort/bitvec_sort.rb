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

    class <<self
      public :new
    end
  end
end
