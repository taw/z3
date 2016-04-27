module Z3
  class IntSort < Sort
    def initialize
      super LowLevel.mk_int_sort
    end

    def expr_class
      IntExpr
    end

    def from_const(val)
      if val.is_a?(Integer)
        new(LowLevel.mk_numeral(val.to_s, self))
      else
        raise Z3::Exception, "Cannot convert #{val.class} to #{self.class}"
      end
    end

    public_class_method :new
  end
end
