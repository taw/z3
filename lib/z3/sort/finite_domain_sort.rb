module Z3
  class FiniteDomainSort < Sort
    attr_reader :name
    def initialize(name, size)
      raise Z3::Exception, "Finite domain size must be a positive Integer" unless size.is_a?(Integer) and size >= 1
      @name = name
      super LowLevel.mk_finite_domain_sort(LowLevel.mk_symbol(name), size)
    end

    def expr_class
      FiniteDomainExpr
    end

    def size
      LowLevel.get_finite_domain_sort_size(_ast)
    end

    def inspect
      "FiniteDomainSort(#{name}, #{size})"
    end

    public_class_method :new
  end
end
