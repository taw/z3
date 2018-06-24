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

class Rational
  prepend CompareHacks
end

class Integer
  prepend CompareHacks
end

class Float
  prepend CompareHacks
end
