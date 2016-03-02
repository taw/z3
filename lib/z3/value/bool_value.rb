module Z3
  class BoolValue < Value
    class <<self
      public :new
    end

    def ~
      ::Z3.Not(self)
    end

    def &(other)
      Z3.And(self, other)
    end

    def |(other)
      Z3.Or(self, other)
    end

    def iff(other)
      Z3.Iff(self, other)
    end

    def implies(other)
      Z3.Implies(self, other)
    end
  end
end
