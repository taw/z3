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
    Z3::Core.Z3_sort_to_string(Z3::Context._context, @_sort)
  end

  def inspect
    "Z3::Sort<#{to_s}>"
  end

  class << self
    def bool
      Z3::Sort.new(Z3::Core.Z3_mk_bool_sort(Z3::Context._context))
    end

    def int
      Z3::Sort.new(Z3::Core.Z3_mk_int_sort(Z3::Context._context))
    end

    def real
      Z3::Sort.new(Z3::Core.Z3_mk_real_sort(Z3::Context._context))
    end
  end
end
