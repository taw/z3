class Z3::Model
  attr_reader :_model
  def initialize(_model)
    @_model = _model
  end

  def num_consts
    Z3::LowLevel.model_get_num_consts(self)
  end

  def num_sorts
    Z3::LowLevel.model_get_num_sorts(self)
  end

  def num_funcs
    Z3::LowLevel.model_get_num_funcs(self)
  end

  def model_eval(ast, model_completion=false)
    Z3::Ast.new(Z3::LowLevel.model_eval(self, ast, model_completion))
  end
end
