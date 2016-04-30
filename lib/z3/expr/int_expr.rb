module Z3
  class IntExpr < ArithExpr
    def mod(other)
      ::Z3.Mod(self, other)
    end

    def rem(other)
      ::Z3.Rem(self, other)
    end

    public_class_method :new
  end
end
