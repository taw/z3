module Z3
  class RealValue < Value
    def +(other)
      ::Z3.Add(self, other)
    end

    def -(other)
      ::Z3.Sub(self, other)
    end

    def *(other)
      ::Z3.Mul(self, other)
    end

    def /(other)
      ::Z3.Div(self, other)
    end

    class <<self
      public :new
    end
  end
end
