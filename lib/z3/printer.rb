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

    # `str.++` is the same operation as `seq.++`, Z3 just names it differently for String
    SEQ_CONCAT_NAMES = ["seq.++", "str.++"]

    def string_value?(decl)
      decl.arity == 0 and decl.num_parameters == 1 and decl.parameter_kind(0) == :zstring
    end

    def char_value?(decl)
      decl.arity == 0 and decl.name == "Char" and decl.num_parameters == 1 and decl.parameter_kind(0) == :int
    end

    def seq_unit?(a)
      a.ast_kind == :app and a.func_decl.name == "seq.unit" and a.sort.is_a?(SeqSort)
    end

    # Concatenation is associative, and models return it as a right-nested binary tree,
    # so flattening it and merging every run of `seq.unit`s into one array literal turns
    # `(seq.++ (seq.unit 1) (seq.++ (seq.unit 2) xs))` into `[1, 2] + xs`
    def format_seq_concat(a)
      parts = flatten_seq_concat(a).chunk{|x| seq_unit?(x)}.flat_map do |unit, exprs|
        if unit
          "[#{exprs.map{|x| format_ast(x.arguments[0])}.join(", ")}]"
        else
          exprs.map{|x| format_ast(x).enforce_parentheses}
        end
      end
      return PrintedExpr.new(parts[0]) if parts.size == 1
      PrintedExpr.new(parts.join(" + "), true)
    end

    def flatten_seq_concat(a)
      return [a] unless a.ast_kind == :app and SEQ_CONCAT_NAMES.include?(a.func_decl.name)
      a.arguments.flat_map{|x| flatten_seq_concat(x)}
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
        args = a.arguments.map{|x| format_ast(x)}

        # String and Char values are indexed decls - `(_ String "abc")` and `(_ Char 97)` -
        # so `decl.name` is just "String"/"Char", and the value is a decl parameter.
        if string_value?(decl)
          return PrintedExpr.new(LowLevel.get_string(a).inspect)
        end
        if char_value?(decl)
          return PrintedExpr.new("Char(#{[LowLevel.get_decl_int_parameter(decl, 0)].pack("U").inspect})")
        end

        # Sequence values, as Ruby array literals
        if a.sort.is_a?(SeqSort)
          case name
          when "seq.unit"
            return PrintedExpr.new("[#{args[0]}]")
          when "seq.empty"
            return PrintedExpr.new("[]")
          end
        end
        if SEQ_CONCAT_NAMES.include?(name) and args.size >= 2
          return format_seq_concat(a)
        end

        # Set operations come back from models as `(_ map and)`, `(_ map or)` etc.
        # `decl.name` is just "map" for all of them, the mapped function is a decl parameter.
        if name == "map" and decl.num_parameters == 1 and decl.parameter_kind(0) == :func_decl
          return PrintedExpr.new("map(#{decl.func_decl_parameter(0).name}, #{args.join(", ")})")
        end

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
