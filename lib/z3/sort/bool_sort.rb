module Z3
  class BoolSort < Sort
    def initialize
      super LowLevel.mk_bool_sort
    end

    def expr_class
      BoolExpr
    end

    def from_const(val)
      if val == true
        BoolExpr.new(LowLevel.mk_true, self)
      elsif val == false
        BoolExpr.new(LowLevel.mk_false, self)
      else
        raise Z3::Exception, "Cannot convert #{val.class} to #{self.class}"
      end
    end

    def True
      from_const(true)
    end

    def False
      from_const(false)
    end

    public_class_method :new
  end
end
