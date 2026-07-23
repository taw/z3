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
        str = Z3::LowLevel.get_numeral_string(a)
        # Rationals print as `157/50`, and negatives carry a leading `-`.
        # Unlike plain integers those are not atomic, so they need parens as a subexpression.
        PrintedExpr.new(str, str !~ /\A\d+\z/)
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
        str = LowLevel::get_numeral_decimal_string(a, 10)
        # a leading - is not atomic, so it needs parens as a subexpression
        PrintedExpr.new(str, str.start_with?("-"))
      elsif LowLevel::is_as_array(a)
        decl = FuncDecl.new( LowLevel::get_as_array_func_decl(a) )
        PrintedExpr.new(decl.sexpr.gsub(/k!\d+/, "k!"))
      elsif a.func_decl.name == "fp.numeral" and a.sort.is_a?(FloatSort)
        # This API chaged in Z3 4.6
        negative = LowLevel::fpa_is_numeral_negative(a)
        s = a.significand_string
        e = "%+d" % a.exponent_string(false).to_i
        # a leading - is not atomic, so it needs parens as a subexpression
        PrintedExpr.new("#{negative ? "-" : ""}#{s}B#{e}", negative)
      else
        decl = a.func_decl
        name = decl.name
        # It looks like Z3 bug, or at least a major quirk
        # various set operations all say (map) when it's really (_ map and), (_ map or) etc.
        if name == "map"
          return a.sexpr.gsub(/\s+/, " ")
        end
        args = a.arguments.map{|x| format_ast(x)}
        return PrintedExpr.new(name, false) if args.size == 0

        # Special case common Bitvec operators
        case name
        when "rotate_left", "rotate_right", "zero_extend", "sign_extend"
          if args.size == 1
            n = Z3::LowLevel.get_decl_int_parameter(a.func_decl, 0)
            return PrintedExpr.new("#{name}(#{args[0]}, #{n})", true)
          end
        when "bvxor", "bvand", "bvor", "bvadd", "bvsub"
          if args.size == 2
            pretty_name = {"bvxor" => "^", "bvand" => "&", "bvor" => "|", "bvadd" => "+", "bvsub" => "-"}[name]
            return PrintedExpr.new("#{args[0].enforce_parentheses} #{pretty_name} #{args[1].enforce_parentheses}", true)
          end
        when "bvnot"
          if args.size == 1
            return PrintedExpr.new("~#{args[0].enforce_parentheses}")
          end
        when "bvneg"
          if args.size == 1
            return PrintedExpr.new("-#{args[0].enforce_parentheses}")
          end
        when "extract"
          if args.size == 1
            u = Z3::LowLevel.get_decl_int_parameter(a.func_decl, 0)
            v = Z3::LowLevel.get_decl_int_parameter(a.func_decl, 1)
            return PrintedExpr.new("#{name}(#{args[0]}, #{u}, #{v})", true)
          end
        end

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
