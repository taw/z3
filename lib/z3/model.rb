class Z3::Model
  include Enumerable

  attr_reader :_model
  def initialize(_model)
    @_model = _model
  end

  def num_consts
    Z3::LowLevel.model_get_num_consts(self)
  end

  def consts
    (0...num_consts).map{|i| Z3::FuncDecl.new(Z3::LowLevel.model_get_const_decl(self, i)) }
  end

  def num_sorts
    Z3::LowLevel.model_get_num_sorts(self)
  end

  def num_funcs
    Z3::LowLevel.model_get_num_funcs(self)
  end

  def model_eval(ast, model_completion=false)
    Z3::Value.new_from_pointer(Z3::LowLevel.model_eval(self, ast, model_completion))
  end

  def [](ast)
    model_eval(ast)
  end

  def to_s
    "Z3::Model<#{ map{|n,v| "#{n}=#{v}"}.join(", ") }>"
  end

  def inspect
    to_s
  end

  def each
    consts.sort_by(&:name).each do |c|
      _ast = Z3::LowLevel.model_get_const_interp(self, c)
      yield(
        c.name,
        Z3::Value.new_from_pointer(_ast)
      )
    end
  end
end
