class Z3::FuncDecl
  attr_reader :_func_decl
  def initialize(_func_decl)
    @_func_decl = _func_decl
  end

  def name
    Z3::LowLevel.get_symbol_string(Z3::LowLevel.get_decl_name(self))
  end

  def to_ast
    Z3::Ast.new(Z3::LowLevel.func_decl_to_ast(self))
  end

  def to_s
    name
  end

  def inspect
    "Z3::FuncDecl<#{name}>"
  end
end
