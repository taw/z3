module Z3
  class Printer
    def format(a)
      case kind = Z3::LowLevel.get_ast_kind(a)
      when 0 # Z3_NUMERAL_AST
        format_numeral(a)
      when 1 # Z3_APP_AST
        format_app(a)
      when 2 # Z3_VAR_AST,
        format_var(a)
      when 3 # Z3_QUANTIFIER_AST,
        format_quantifier(a)
      when 4 # Z3_SORT_AST
        format_func_decl(a)
      when 1000 # Z3_UNKNOWN_AST = 1000
        format_unknown(a)
      else
        raise Z3::Exception, "Unknown AST kind #{kind}"
      end
    end

    def format_numeral(a)
      Z3::LowLevel.get_numeral_string(a)
    end
  end
end
