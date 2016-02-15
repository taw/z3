class Z3::Sort
  attr_reader :_sort
  # Do not use .new directly
  def initialize(_sort)
    @_sort = _sort
  end

  def ==(other)
    other.is_a?(Z3::Sort) and @_sort == other._sort
  end

  def to_s
    Z3::LowLevel.sort_to_string(self)
  end

  def inspect
    "Z3::Sort<#{to_s}>"
  end

  class << self
    def bool
      Z3::Sort.new(Z3::LowLevel.mk_bool_sort)
    end

    def int
      Z3::Sort.new(Z3::LowLevel.mk_int_sort)
    end

    def real
      Z3::Sort.new(Z3::LowLevel.mk_real_sort)
    end
  end
end
