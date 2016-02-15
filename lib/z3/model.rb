class Z3::Model
  def initialize(_model, ctx: Z3::Context.main)
    @ctx = ctx
    @_model = _model
  end
end
