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
      a, b = other.coerce(self)
      return a == b
    end
    super
  end

  def !=(other)
    if other.is_a?(Z3::Expr)
      a, b = other.coerce(self)
      return a != b
    end
    super
  end

  def >=(other)
    if other.is_a?(Z3::Expr)
      a, b = other.coerce(self)
      return a >= b
    end
    super
  end

  def >(other)
    if other.is_a?(Z3::Expr)
      a, b = other.coerce(self)
      return a > b
    end
    super
  end

  def <=(other)
    if other.is_a?(Z3::Expr)
      a, b = other.coerce(self)
      return a <= b
    end
    super
  end

  def <(other)
    if other.is_a?(Z3::Expr)
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

# A Symbol is an enum value, so `:red == color_var` needs to build an expression the
# same way `color_var == :red` does. Not CompareHacks - enum values are unordered.
class Symbol
  prepend EqualityHacks
end

# An Array or a Hash is a tuple's fields, the two ways of writing the same value -
# `point == [1, 2]` and `point == {x: 1, y: 2}` build the identical term. Without this
# the flipped form answered a plain Ruby `false`, which is the one shape of this bug
# that's silently wrong rather than an exception. Not CompareHacks - tuples are
# unordered, and neither is anything else these two could stand for.
class Array
  prepend EqualityHacks
end

class Hash
  prepend EqualityHacks
end

# A Set is a finite set's elements, so it needs the flipped form too. Array already has
# it just above, for tuples, and means a finite set as well when that's the sort it's
# meeting. Range deliberately doesn't: it isn't a set value here, because it isn't one
# in Ruby either.
#
# Not CompareHacks: Ruby's Set#<= is the subset question, and routing that through
# `coerce` would ask it of two Z3 expressions rather than answering it, which is a
# different thing from what the arithmetic operators do.
require "set"

class Set
  prepend EqualityHacks
end

# NilClass and the rest of Object deliberately don't get this. They're not Z3 values,
# so `nil == int_var` would have to raise to match `int_var == nil`, and Ruby calls
# `==` on nil all over the place - `[nil, x].include?(y)` asks `nil == y` - where an
# exception in place of `false` would be far worse than the asymmetry.

class Rational
  prepend CompareHacks
end

class Integer
  prepend CompareHacks
end

class Float
  prepend CompareHacks
end
