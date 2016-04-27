module Z3
  class Printer
    def format(a)
      case a.ast_kind
      when :numeral
        format_numeral(a)
      when :app
        a.sexpr
      when :var
        a.sexpr
      when :quantifier
        a.sexpr
      when :func_decl
        a.sexpr
      when :unknown
        a.sexpr
      else
        raise Z3::Exception, "Unknown AST kind #{a.ast_kind}"
      end
    end

    def format_numeral(a)
      Z3::LowLevel.get_numeral_string(a)
    end
  end
end
