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
      kind_id = LowLevel.get_ast_kind(self)
      ast_kind_lookup[kind_id] or raise Z3::Exception, "Unknown AST kind #{kind_id}"
    end

    def func_decl
      raise Z3::Exception, "Only app ASTs can have func decls" unless ast_kind == :app
      FuncDecl.new(LowLevel::get_app_decl(self))
    end

    def arguments
      raise Z3::Exception, "Only app ASTs can have arguments" unless ast_kind == :app
      num = LowLevel::get_app_num_args(self)
      (0...num).map do |i|
        _ast = LowLevel::get_app_arg(self, i)
        Expr.new_from_pointer(_ast)
      end
    end

    def to_s
      Printer.new.format(self)
    end

    def sexpr
      LowLevel.ast_to_string(self)
    end

    def simplify
      sort.new(LowLevel.simplify(self))
    end

    def eql?(other)
      self.class == other.class and self._ast == other._ast
    end

    def hash
      _ast.address
    end

    # How a value gets named in an error message. Ruby writes nil / true / false
    # literally and everything else by class - `Integer(nil)` says "can't convert nil
    # into Integer", not "can't convert NilClass into Integer" - and an Expr goes by
    # its sort, which is what any mismatch involving one is really about. A Symbol
    # joins the literal group: it's an enum value, and which one it was is the whole
    # of what went wrong.
    def self.describe(value)
      case value
      when NilClass, TrueClass, FalseClass, Symbol
        value.inspect
      when Expr
        value.sort
      else
        value.class
      end
    end

    private_class_method :new
  end
end
