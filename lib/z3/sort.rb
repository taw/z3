class Z3::Sort
  attr_reader :_sort
  # Do not use .new directly
  def initialize(_sort, ctx:Z3::Context.main)
    @ctx = ctx
    @_sort = _sort
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
