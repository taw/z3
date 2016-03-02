module Z3
  class Value
    attr_reader :_ast, :sort
    def initialize(_ast, sort)
      @_ast = _ast
      @sort = sort
    end

    def to_s
      Z3::LowLevel.ast_to_string(self)
    end

    def inspect
      "#{self.class}<#{to_s} :: #{sort.to_s}>"
    end

    def ==(other)
      ::Z3.Eq(self, other)
    end

    def !=(other)
      ::Z3.Distinct(self, other)
    end

    def >(other)
      ::Z3.Gt(self, other)
    end

    def >=(other)
      ::Z3.Ge(self, other)
    end

    def <=(other)
      ::Z3.Lt(self, other)
    end

    def <(other)
      ::Z3.Le(self, other)
    end

    class << self
      private :new
    end
  end
end
