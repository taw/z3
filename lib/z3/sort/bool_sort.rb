module Z3
  class BoolSort < Sort
    def initialize
      super LowLevel.mk_bool_sort
    end

    def value_class
      BoolValue
    end

    def from_const(val)
      if val == true
        BoolValue.new(LowLevel.mk_true, self)
      elsif val == false
        BoolValue.new(LowLevel.mk_false, self)
      else
        raise Z3::Exception, "Cannot convert #{val.class} to #{self.class}"
      end
    end

    def True
      from_value(true)
    end

    def False
      from_value(false)
    end

    class <<self
      public :new
    end
  end
end
