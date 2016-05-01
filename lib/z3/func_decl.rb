module Z3
  class FuncDecl < AST
    def initialize(_ast)
      super(_ast)
      raise Z3::Exception, "FuncDecls must have AST kind func decl" unless ast_kind == :func_decl
    end

    def name
      LowLevel.get_symbol_string(LowLevel.get_decl_name(self))
    end

    def arity
      LowLevel.get_arity(self)
    end

    def domain(i)
      a = arity
      raise Z3::Exception, "Trying to access domain #{i} but function arity is #{a}" if i < 0 or i >= a
      Sort.from_pointer(LowLevel::get_domain(self, i))
    end

    def range
      Sort.from_pointer(LowLevel::get_range(self))
    end

    # def ast_parameter(i)
    #   # vs arity ?
    #   Z3::Ast.new(LowLevel.get_decl_ast_parameter(self, i))
    # end

    def to_s
      name
    end

    def inspect
      "Z3::FuncDecl<#{name}/#{arity}>"
    end

    public_class_method :new
  end
end
