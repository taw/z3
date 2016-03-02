module Z3
  class BoolValue < Value
    class <<self
      public :new
    end

    def ~
      ::Z3.Not(self)
    end
  end
end
