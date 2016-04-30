module Z3
  class Printer
    def format(a)
      case a.ast_kind
      when :numeral
        format_numeral(a)
      when :app
        format_app(a)
      when :var, :quantifier, :func_decl, :unknown
        a.sexpr
      else
        raise Z3::Exception, "Unknown AST kind #{a.ast_kind}"
      end
    end

    def format_numeral(a)
      Z3::LowLevel.get_numeral_string(a)
    end

    def format_app(a)
      if LowLevel::is_algebraic_number(a)
        return LowLevel::get_numeral_decimal_string(a, 10)
      end
      decl = a.func_decl
      name = decl.name
      args = a.arguments
      return name if args.size == 0
      # All operators
      if name !~ /[a-z0-9]/
        if args.size == 2
          return "(#{args[0]} #{name} #{args[1]})"
        elsif args.size == 1
          return "(#{name} #{args[0]})"
        end
      end
      "#{name}(#{args.join(", ")})"
    end
  end
end
