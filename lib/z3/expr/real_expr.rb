module Z3
  class RealExpr < ArithExpr
    # There's no #value here, unlike every other sort which can hand back a Ruby
    # object. Z3's Reals include the algebraic numbers, and √2 has no exact Ruby
    # equivalent at all - so instead there's #to_r, which is exact and refuses when it
    # can't be, and #to_f, which is an approximation and says so by being a Float.
    def to_r
      value = as_literal
      if value.algebraic?
        raise Z3::Exception, "Can't convert algebraic number #{value} into an exact Rational, use #to_f or #lower_bound / #upper_bound"
      end
      Rational(
        Expr.new_from_pointer(LowLevel.get_numerator(value)).to_i,
        Expr.new_from_pointer(LowLevel.get_denominator(value)).to_i,
      )
    end

    # Always available, because a Float is allowed to be approximate
    def to_f
      value = as_literal
      return LowLevel.get_numeral_double(value) unless value.algebraic?
      # Far more precision than a Float can hold, so both ends of the interval round
      # to the same double and it doesn't matter which one we take
      value.lower_bound.to_f
    end

    # Z3 answers an irrational root with an algebraic number rather than giving up,
    # and those are `:app` rather than `:numeral`, so #ast_kind won't spot them
    def algebraic?
      LowLevel.is_algebraic_number(self)
    end

    # Rationals bracketing the value, as tightly as `precision` asks for.
    # An exact value is its own bound.
    def lower_bound(precision = 20)
      value = as_literal
      return value.to_r unless value.algebraic?
      Expr.new_from_pointer(LowLevel.get_algebraic_number_lower(value, precision)).to_r
    end

    def upper_bound(precision = 20)
      value = as_literal
      return value.to_r unless value.algebraic?
      Expr.new_from_pointer(LowLevel.get_algebraic_number_upper(value, precision)).to_r
    end

    # SMT-LIB's `to_int` rounds towards negative infinity, so this is Ruby's
    # Float#floor. Deliberately not #to_i, which truncates towards zero instead -
    # `(-2.5).to_i` is -2 in Ruby, but this is -3.
    def floor
      IntSort.new.new(LowLevel.mk_real2int(self))
    end

    # A Z3 Bool, like #zero? and the other predicates, not a Ruby one
    def integer?
      BoolSort.new.new(LowLevel.mk_is_int(self))
    end

    public_class_method :new

    private

    # Model values arrive already reduced, anything else has to be simplified first
    def as_literal
      return self if ast_kind == :numeral or algebraic?
      simplified = simplify
      unless simplified.ast_kind == :numeral or simplified.algebraic?
        raise Z3::Exception, "Can't convert expression #{self} into a number"
      end
      simplified
    end
  end
end
