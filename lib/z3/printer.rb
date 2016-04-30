module Z3
  class Printer
    def format(a)
      format_ast(a).to_s
    end

    private

    class PrintedExpr
      attr_reader :str, :priority
      def initialize(str, priority)
        @str = str
        @priority = priority
      end
      def to_s
        @str
      end
      def enforce_parentheses
        if @priority
          "(#{@str})"
        else
          @str
        end
      end
    end

    def format_ast(a)
      case a.ast_kind
      when :numeral
        PrintedExpr.new(Z3::LowLevel.get_numeral_string(a), false)
      when :app
        format_app(a)
      when :var, :quantifier, :func_decl, :unknown
        PrintedExpr.new(a.sexpr, false)
      else
        raise Z3::Exception, "Unknown AST kind #{a.ast_kind}"
      end
    end

    def format_app(a)
      if LowLevel::is_algebraic_number(a)
        return LowLevel::get_numeral_decimal_string(a, 10)
      end
      decl = a.func_decl
      name = decl.name
      args = a.arguments.map{|x| format_ast(x)}
      return PrintedExpr.new(name, false) if args.size == 0
      # All operators
      if name !~ /[a-z0-9]/
        if args.size == 2
          return PrintedExpr.new("#{args[0].enforce_parentheses} #{name} #{args[1].enforce_parentheses}", true)
        elsif args.size == 1
          return PrintedExpr.new("#{name}#{args[0].enforce_parentheses}", true)
        end
      end
      PrintedExpr.new("#{name}(#{args.join(", ")})", false)
    end
  end
end
