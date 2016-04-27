module Z3
  class AST
    attr_reader :_ast
    def initialize(_ast)
      raise Z3::Exception, "AST expected, got #{_ast.class}" unless _ast.is_a?(FFI::Pointer)
      @_ast = _ast
    end

    def ast_kind
      ast_kind_lookup = {
        0 => :numeral,
        1 => :app,
        2 => :var,
        3 => :quantifier,
        4 => :sort,
        5 => :func_decl,
        1000 => :unknown,
      }
      kind_id = Z3::LowLevel.get_ast_kind(self)
      ast_kind_lookup[kind_id] or raise Z3::Exception, "Unknown AST kind #{kind_id}"
    end

    def to_s
      Z3::Printer.new.format(self)
    end

    def sexpr
      Z3::LowLevel.ast_to_string(self)
    end

    private_class_method :new
  end
end
