# This is going to slow down ruby, but the alternative is very inconsistent API
module EqualityHacks
  def ==(other)
    if other.is_a?(Z3::Expr)
      return other == self
    end
    super
  end

  def !=(other)
    if other.is_a?(Z3::Expr)
      return other != self
    end
    super
  end
end

module CompareHacks
  def ==(other)
    if other.is_a?(Z3::Expr)
      raise ArgumentError.new unless other.respond_to?(:coerce)
      a, b = other.coerce(self)
      return a == b
    end
    super
  end

  def !=(other)
    if other.is_a?(Z3::Expr)
      raise ArgumentError.new unless other.respond_to?(:coerce)
      a, b = other.coerce(self)
      return a != b
    end
    super
  end

  def >=(other)
    if other.is_a?(Z3::Expr)
      raise ArgumentError.new unless other.respond_to?(:coerce)
      a, b = other.coerce(self)
      return a >= b
    end
    super
  end

  def >(other)
    if other.is_a?(Z3::Expr)
      raise ArgumentError.new unless other.respond_to?(:coerce)
      a, b = other.coerce(self)
      return a > b
    end
    super
  end

  def <=(other)
    if other.is_a?(Z3::Expr)
      raise ArgumentError.new unless other.respond_to?(:coerce)
      a, b = other.coerce(self)
      return a <= b
    end
    super
  end

  def <(other)
    if other.is_a?(Z3::Expr)
      raise ArgumentError.new unless other.respond_to?(:coerce)
      a, b = other.coerce(self)
      return a < b
    end
    super
  end
end

class TrueClass
  prepend EqualityHacks
end

class FalseClass
  prepend EqualityHacks
end

# Strings don't get CompareHacks, because that routes through `coerce`, and a String
# has no sort to coerce towards - `"a" < int_expr` is a sort mismatch, not an
# arithmetic one. Flipping the operator round to the Expr says the same thing and lets
# StringExpr raise its own error.
module StringHacks
  def +(other)
    return Z3::StringExpr.Concat(self, other) if other.is_a?(Z3::Expr)
    super
  end

  def <(other)
    return other > self if other.is_a?(Z3::Expr)
    super
  end

  def <=(other)
    return other >= self if other.is_a?(Z3::Expr)
    super
  end

  def >(other)
    return other < self if other.is_a?(Z3::Expr)
    super
  end

  def >=(other)
    return other <= self if other.is_a?(Z3::Expr)
    super
  end
end

class String
  prepend EqualityHacks
  prepend StringHacks
end

class Rational
  prepend CompareHacks
end

class Integer
  prepend CompareHacks
end

class Float
  prepend CompareHacks
end
