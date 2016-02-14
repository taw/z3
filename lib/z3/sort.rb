class Z3::Sort
  attr_reader :_sort, :ctx
  # Do not use .new directly
  def initialize(_sort, ctx: Z3::Context.main)
    @ctx = ctx
    @_sort = _sort
  end

  def ==(other)
    other.is_a?(Z3::Sort) and @_sort == other._sort
  end

  def to_s
    Z3::Core.Z3_sort_to_string(@ctx._context, @_sort)
  end

  def inspect
    "Z3::Sort<#{to_s}>"
  end

  class << self
    def bool(ctx: Z3::Context.main)
      Z3::Sort.new(Z3::Core::Z3_mk_bool_sort(ctx._context), ctx: ctx)
    end

    def int(ctx: Z3::Context.main)
      Z3::Sort.new(Z3::Core::Z3_mk_int_sort(ctx._context), ctx: ctx)
    end

    def real(ctx: Z3::Context.main)
      Z3::Sort.new(Z3::Core::Z3_mk_real_sort(ctx._context), ctx: ctx)
    end
  end
end
