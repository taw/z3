module Z3
  class Printer
    def format(a)
      format_ast(a).to_s
    end

    private

    class PrintedExpr
      attr_reader :str, :priority
      def initialize(str, priority=false)
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
        PrintedExpr.new(Z3::LowLevel.get_numeral_string(a))
      when :app
        format_app(a)
      when :var, :quantifier, :func_decl, :unknown
        PrintedExpr.new(a.sexpr)
      else
        raise Z3::Exception, "Unknown AST kind #{a.ast_kind}"
      end
    end

    def format_app(a)
      if LowLevel::is_algebraic_number(a)
        PrintedExpr.new(LowLevel::get_numeral_decimal_string(a, 10))
      elsif LowLevel::is_as_array(a)
        decl = FuncDecl.new( LowLevel::get_as_array_func_decl(a) )
        PrintedExpr.new(decl.sexpr.gsub(/k!\d+/, "k!"))
      elsif a.func_decl.name == "fp.numeral" and a.sort.is_a?(FloatSort)
        s = a.significand_string
        # Z3 4.6 changed how #exponent_string it works, it returns it unbiased
        # Before it was biased
        bias = a.sort.from_const(1).exponent_string.to_i
        if bias == 0
          e = a.exponent_string.to_i
        else
          e = a.exponent_string.to_i
          if e == 0
            e -= bias - 1
          else
            e -= bias
          end
        end
        e = "%+d" % e
        PrintedExpr.new("#{s}B#{e}")
      else
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
        PrintedExpr.new("#{name}(#{args.join(", ")})")
      end
    end
  end
end
