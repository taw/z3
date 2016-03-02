module Z3
  class RealSort < Sort
    def initialize
      super LowLevel.mk_real_sort
    end

    def value_class
      RealValue
    end

    public_class_method :new
  end
end
