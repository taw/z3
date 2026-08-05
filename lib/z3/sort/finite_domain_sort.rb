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

    # The sort's values are 0 to `size - 1` and Z3 names none of them, so a Ruby
    # Integer in range is all a value can be built from - FiniteDomainExpr#value reads
    # one back. Z3 rejects an out of range value itself, without saying what the range
    # was or which sort had it.
    #
    # A Ruby Integer means an Int everywhere else, so it isn't coerced into this sort
    # the way it is into a Bitvec - `x == 3` is a sort mismatch and
    # `x == sort.from_const(3)` is how to say it.
    def from_const(val)
      raise cant_convert(val) unless val.is_a?(Integer)
      raise Z3::Exception, "#{self} value must be between 0 and #{size - 1}" unless (0...size).cover?(val)
      new(LowLevel.mk_numeral(val.to_s, self))
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
