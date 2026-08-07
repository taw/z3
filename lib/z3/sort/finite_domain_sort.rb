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
    def from_const(val)
      raise cant_convert(val) unless val.is_a?(Integer)
      raise Z3::Exception, "#{self} value must be between 0 and #{size - 1}" unless (0...size).cover?(val)
      new(LowLevel.mk_numeral(val.to_s, self))
    end

    def size
      LowLevel.get_finite_domain_sort_size(_ast)
    end

    # A Ruby Integer means an Int, so `x == 3` would be a sort mismatch without this -
    # claiming Int here is what makes #coerce_to_same_sort pick this sort and send the
    # 3 through #from_const. `BitvecSort` and `FloatSort` say the same thing for the
    # same reason, each with a `# This is nasty...` next to it, and nasty is right: a
    # finite domain of 10 values is not a supersort of Int, it's very much smaller, and
    # the claim is here to make a cast fire rather than because it's true.
    #
    # What keeps it honest is that it only ever reaches Ruby values. `from_value` isn't
    # overridden, so it still refuses every Expr of another sort - `x == int_var` and
    # `int_var + x` raise exactly as before, just from the other end of the conversion.
    # And unlike a Bitvec, which has to accept both `-1` and `255` at width 8 and so
    # can't check a range at all, this sort's values are 0 to `size - 1` with no signed
    # reading to argue about, so `x == 300` raises rather than quietly wrapping.
    def >(other)
      raise ArgumentError unless other.is_a?(Sort)
      other.is_a?(IntSort)
    end

    def inspect
      "FiniteDomainSort(#{name}, #{size})"
    end

    public_class_method :new
  end
end
