class Z3::Model
  def initialize(_model, cxt: Z3::Context.main)
    @ctx = ctx
    @_model = model
  end
end
