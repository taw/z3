module Z3
  class Printer
    def format(a)
      format_ast(a).to_s
    end

    # A model value, which is an Expr for a constant but a Hash for a function.
    # Hash#inspect leaves the default out, and for a function interpretation the
    # default *is* the answer everywhere the model didn't say otherwise, so printing
    # without it would be printing the least useful half.
    def format_value(value)
      return value.to_s unless value.is_a?(Hash)
      cases = value.map { |args, result| "(#{args.join(", ")}) => #{result}" }
      "{#{(cases << "else => #{value.default}").join(", ")}}"
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

    # Z3 decl name => Ruby method, printed as `receiver.method` or
    # `receiver.method(rest)` with the first argument as the receiver. Z3 names the
    # same operation `str.foo` for Strings and `seq.foo` for every other Seq, so both
    # spellings map to the one Ruby method - except `replace_all`, which Z3 calls
    # `str.replace_all` even for sequences of non-characters.
    METHOD_CALL_NAMES = {
      "seq.len" => "size",
      "str.len" => "size",
      "seq.contains" => "include?",
      "str.contains" => "include?",
      "seq.indexof" => "index",
      "str.indexof" => "index",
      "seq.last_indexof" => "rindex",
      "seq.replace" => "sub",
      "str.replace" => "sub",
      "seq.replace_all" => "gsub",
      "str.replace_all" => "gsub",
      "str.to_int" => "to_i",
      # `str.replace_re` / `str.replace_re_all` are the same Ruby methods as
      # `str.replace` / `str.replace_all` - #sub and #gsub take a Re pattern too
      "str.replace_re" => "sub",
      "str.replace_re_all" => "gsub",
      "str.in_re" => "matches?",
      "seq.in.re" => "matches?",
      "set.size" => "size",
      "set.subset" => "subset?",
    }

    # Same idea, but Z3 takes the prefix/suffix first and the string second, where
    # Ruby's String#start_with? / #end_with? take it the other way round - so it's the
    # *second* argument that prints as the receiver.
    FLIPPED_METHOD_CALL_NAMES = {
      "seq.prefixof" => "start_with?",
      "str.prefixof" => "start_with?",
      "seq.suffixof" => "end_with?",
      "str.suffixof" => "end_with?",
      # `set.in` takes the element first and the set second, Ruby's Set#include? the
      # other way round
      "set.in" => "include?",
    }

    # Lexicographic string comparison. These are operators in Ruby, but their Z3 names
    # contain letters, so the generic operator path doesn't catch them.
    OPERATOR_NAMES = {
      "str.<" => "<",
      "str.<=" => "<=",
    }

    # Z3 always spells the starting offset out, Ruby's String#index / Array#index
    # default it to 0 - so a trailing 0 is noise, and `s.index("a")` is what anyone
    # would have written
    DEFAULT_TRAILING_ARG = {
      "seq.indexof" => "0",
      "str.indexof" => "0",
    }

    # Argument positions that take an element-or-subsequence. `xs.include?(7)` builds
    # `(seq.contains xs (seq.unit 7))`, and printing that back as `xs.include?([7])` is
    # correct but isn't what anyone wrote - Ruby's Array#include? takes the element, so
    # a lone unit in one of these positions prints as the element it wraps.
    SEQ_ELEMENT_ARGS = {
      "seq.contains" => [1],
      "seq.indexof" => [1],
      "seq.last_indexof" => [1],
      "seq.prefixof" => [0],
      "seq.suffixof" => [0],
      "seq.replace" => [1, 2],
      "seq.replace_all" => [1, 2],
      # Z3 uses the `str.` name here even for sequences of non-characters. A String
      # argument is never a `seq.unit`, so this is a no-op for actual strings.
      "str.replace_all" => [1, 2],
      # Only the replacement - argument 1 of these two is a regex, not a sequence
      "str.replace_re" => [2],
      "str.replace_re_all" => [2],
    }

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

    # Finite set operations that print as Ruby operators. `set.union` is not in here
    # because it also has to merge singletons into a Set literal - see below.
    FINITE_SET_OPERATOR_NAMES = {
      "set.intersect" => "&",
      "set.difference" => "-",
    }

    def finite_set_singleton?(a)
      a.ast_kind == :app and a.func_decl.name == "set.singleton"
    end

    # Set values as Ruby Set literals, and the rest of the finite set vocabulary as
    # the methods and operators it's written with. `set.size`, `set.subset` and
    # `set.in` aren't here - they're ordinary method calls, and the tables above have
    # them.
    def format_finite_set(a, name, args)
      case name
      when "set.empty"
        # No element sort in it, the same way an empty sequence prints as `[]`
        return PrintedExpr.new("Set[]")
      when "set.singleton"
        return PrintedExpr.new("Set[#{args[0]}]") if args.size == 1
      when "set.range"
        # A Range is what builds one of these, and unlike `Set[1, 2, 3]` it stays
        # right when an end is symbolic
        return PrintedExpr.new("(#{args[0]}..#{args[1]})") if args.size == 2
      when "set.union"
        return format_finite_set_union(a) if args.size >= 2
      when "set.map"
        return PrintedExpr.new("#{args[1].enforce_parentheses}.map(#{args[0]})") if args.size == 2
      when "set.filter"
        return PrintedExpr.new("#{args[1].enforce_parentheses}.select(#{args[0]})") if args.size == 2
      end
      operator = FINITE_SET_OPERATOR_NAMES[name]
      return nil unless operator and args.size == 2
      PrintedExpr.new("#{args[0].enforce_parentheses} #{operator} #{args[1].enforce_parentheses}", true)
    end

    # Union is associative, and models return it nested any which way and at any
    # arity, so flattening it and merging every run of singletons into one Set literal
    # turns `(set.union (set.singleton 1) (set.union (set.singleton 2) xs))` into
    # `Set[1, 2] | xs`. Exactly what format_seq_concat does for sequences.
    def format_finite_set_union(a)
      parts = flatten_finite_set_union(a).chunk{|x| finite_set_singleton?(x)}.flat_map do |singleton, exprs|
        if singleton
          "Set[#{exprs.map{|x| format_ast(x.arguments[0])}.join(", ")}]"
        else
          exprs.map{|x| format_ast(x).enforce_parentheses}
        end
      end
      return PrintedExpr.new(parts[0]) if parts.size == 1
      PrintedExpr.new(parts.join(" | "), true)
    end

    def flatten_finite_set_union(a)
      return [a] unless a.ast_kind == :app and a.func_decl.name == "set.union"
      a.arguments.flat_map{|x| flatten_finite_set_union(x)}
    end

    # A method call binds tighter than any operator, so the result is atomic - only
    # the receiver can need parentheses
    def format_method_call(name, args)
      method = METHOD_CALL_NAMES[name]
      return nil unless method and args.size >= 1
      receiver, *rest = args
      rest.pop if DEFAULT_TRAILING_ARG[name] == rest.last&.to_s
      if rest.empty?
        PrintedExpr.new("#{receiver.enforce_parentheses}.#{method}")
      else
        PrintedExpr.new("#{receiver.enforce_parentheses}.#{method}(#{rest.join(", ")})")
      end
    end

    def format_flipped_method_call(name, args)
      method = FLIPPED_METHOD_CALL_NAMES[name]
      return nil unless method and args.size == 2
      PrintedExpr.new("#{args[1].enforce_parentheses}.#{method}(#{args[0]})")
    end

    # The map and fold family, which needs its own shape: Z3 takes the sequence
    # *last* and the rest in an order the Ruby methods don't share, so
    # `(seq.fold_left f a xs)` is `xs.inject(a, f)`. The Ruby names are the primary
    # ones - #mapi, #fold_left and #fold_lefti exist as aliases, but nothing prints
    # as them. Z3 uses the `seq.` names for Strings too, so this covers both.
    def format_seq_map_fold(name, args)
      case name
      when "seq.map"
        seq_map_fold_call(args[1], "map", [args[0]]) if args.size == 2
      when "seq.mapi"
        seq_map_fold_call(args[2], "map_with_index", [args[0]], args[1]) if args.size == 3
      when "seq.fold_left"
        seq_map_fold_call(args[2], "inject", [args[1], args[0]]) if args.size == 3
      when "seq.fold_lefti"
        seq_map_fold_call(args[3], "inject_with_index", [args[2], args[0]], args[1]) if args.size == 4
      end
    end

    # `from:` is 0 by default on the Ruby side, so it prints only when it isn't -
    # the same reason `seq.indexof`'s trailing 0 doesn't print
    def seq_map_fold_call(receiver, method, rest, from = nil)
      rest = rest.map(&:to_s)
      rest << "from: #{from}" unless from.nil? or from.to_s == "0"
      PrintedExpr.new("#{receiver.enforce_parentheses}.#{method}(#{rest.join(", ")})")
    end

    # Ruby indexing. `str.at` gives a one character String, so it's `s[i]` - but
    # `seq.at` gives a one element Seq, which in Ruby is `xs[i, 1]`, because `xs[i]`
    # on a Seq is the element itself (`seq.nth`).
    def format_index(a, name, args)
      case name
      when "str.at"
        PrintedExpr.new("#{args[0].enforce_parentheses}[#{args[1]}]") if args.size == 2
      when "seq.at"
        PrintedExpr.new("#{args[0].enforce_parentheses}[#{args[1]}, 1]") if args.size == 2
      when "seq.nth"
        # `seq.nth` of a String is a Char, and StringExpr has no Ruby method for that -
        # `s[i]` there is `str.at`, a one character String
        return nil if args.size != 2 or a.arguments[0].sort.is_a?(StringSort)
        PrintedExpr.new("#{args[0].enforce_parentheses}[#{args[1]}]")
      when "str.substr", "seq.extract"
        PrintedExpr.new("#{args[0].enforce_parentheses}[#{args[1]}, #{args[2]}]") if args.size == 3
      end
    end

    # Regex operations that print as Ruby operators on ReExpr. `re.++` is
    # concatenation and `re.+` is one-or-more - different Z3 names, so no clash.
    RE_OPERATOR_NAMES = {
      "re.++" => "+",
      "re.union" => "|",
      "re.inter" => "&",
      "re.diff" => "-",
    }

    # ...and the ones that print as methods, since Ruby has no operators to spare
    RE_METHOD_NAMES = {
      "re.*" => "star",
      "re.+" => "plus",
      "re.opt" => "option",
    }

    # Concat, union and intersection are associative, and Z3 hands them back as a
    # nested binary tree however many arguments they were built with
    RE_ASSOCIATIVE_NAMES = ["re.++", "re.union", "re.inter"]

    # The regexes with no arguments at all, named after the constructors that build
    # them. Z3 calls the empty language `re.none` over Strings and `re.empty` over
    # every other sequence sort.
    RE_CONSTANT_NAMES = {
      "re.none" => "Empty",
      "re.empty" => "Empty",
      "re.all" => "Full",
      "re.allchar" => "AllChar",
    }

    # A regex sort is only worth spelling out when it isn't the String one, which is
    # what `Re.Empty` and friends default to
    def re_basis_arg(a)
      return "" unless a.sort.is_a?(ReSort) and a.sort.seq_sort != StringSort.new
      "(#{a.sort.seq_sort})"
    end

    # Regexes have no Ruby literal - `Re.Of` and `Re.Range` are how they're built, so
    # that's how they print, rather than as `str.to_re` / `re.range`
    def format_re(a, name, args)
      if RE_CONSTANT_NAMES[name] and args.empty?
        return PrintedExpr.new("Re.#{RE_CONSTANT_NAMES[name]}#{re_basis_arg(a)}")
      end
      case name
      when "str.to_re", "seq.to.re"
        return PrintedExpr.new("Re.Of(#{args[0]})") if args.size == 1
      when "re.range"
        return PrintedExpr.new("Re.Range(#{args.join(", ")})") if args.size == 2
      when "re.comp"
        return PrintedExpr.new("~#{args[0].enforce_parentheses}", true) if args.size == 1
      when "re.^"
        n = Z3::LowLevel.get_decl_int_parameter(a.func_decl, 0)
        return PrintedExpr.new("#{args[0].enforce_parentheses} * #{n}", true) if args.size == 1
      when "re.loop"
        return nil unless args.size == 1
        decl = a.func_decl
        from = Z3::LowLevel.get_decl_int_parameter(decl, 0)
        # Z3 drops the upper bound from the decl entirely when there isn't one
        to = decl.num_parameters >= 2 ? Z3::LowLevel.get_decl_int_parameter(decl, 1) : nil
        return PrintedExpr.new("#{args[0].enforce_parentheses} * (#{from}..#{to})", true)
      end
      if RE_METHOD_NAMES[name] and args.size == 1
        return PrintedExpr.new("#{args[0].enforce_parentheses}.#{RE_METHOD_NAMES[name]}")
      end
      if RE_OPERATOR_NAMES[name] and args.size >= 2
        parts = if RE_ASSOCIATIVE_NAMES.include?(name)
          flatten_re(a, name).map { |x| format_ast(x).enforce_parentheses }
        else
          args.map(&:enforce_parentheses)
        end
        return PrintedExpr.new(parts.join(" #{RE_OPERATOR_NAMES[name]} "), true)
      end
      nil
    end

    def flatten_re(a, name)
      return [a] unless a.ast_kind == :app and a.func_decl.name == name
      a.arguments.flat_map { |x| flatten_re(x, name) }
    end

    # Cardinality constraints are indexed decls: the bound, and for the weighted forms
    # one weight per argument, are decl parameters rather than arguments. Printing the
    # arguments alone made `AtMost([a, b], 1)` and `AtMost([a, b], 2)` the same string,
    # so these print back as the Ruby that builds them. Unit-weight `pble`/`pbge` never
    # reach here - Z3 normalises those into `at-most`/`at-least` - but a unit-weight
    # `pbeq` does, because Z3 has no unweighted spelling of it.
    PSEUDO_BOOLEAN_NAMES = {
      "at-most"  => "AtMost",
      "at-least" => "AtLeast",
      "pble"     => "AtMost",
      "pbge"     => "AtLeast",
      "pbeq"     => "Exactly",
    }

    def format_pseudo_boolean(a, name, args)
      method = PSEUDO_BOOLEAN_NAMES[name]
      decl = a.func_decl
      return nil unless method and decl.num_parameters >= 1 and decl.parameter_kind(0) == :int
      bound = decl.parameter(0)
      weights = (1...decl.num_parameters).map { |i| decl.parameter(i) }
      if weights.all?{|w| w == 1} and weights.size == args.size
        return PrintedExpr.new("#{method}([#{args.join(", ")}], #{bound})")
      end
      return PrintedExpr.new("#{method}([#{args.join(", ")}], #{bound})") if weights.empty?
      return nil unless weights.size == args.size
      pairs = args.zip(weights).map{|arg, weight| "#{arg} => #{weight}"}
      PrintedExpr.new("#{method}({#{pairs.join(", ")}}, #{bound})")
    end

    # Array and Set reads and writes. Z3 has one `select` and one `store` for both,
    # because a Set is an `Array(X, Bool)` - so which Ruby spelling they get is decided
    # by the receiver's sort. `select` has no Ruby name of its own on either: indexing
    # is `[]` and membership is `#include?`, and `select` means something else entirely
    # in Ruby.
    #
    # The sort check is also what keeps a user function called `store` or `select` out
    # of here.
    def format_array(a, name, args)
      return nil unless args.size >= 1
      receiver_sort = a.arguments[0].sort
      return nil unless receiver_sort.is_a?(ArraySort) or receiver_sort.is_a?(SetSort)
      case name
      when "select"
        return nil unless args.size == 2
        if receiver_sort.is_a?(SetSort)
          PrintedExpr.new("#{args[0].enforce_parentheses}.include?(#{args[1]})")
        else
          PrintedExpr.new("#{args[0].enforce_parentheses}[#{args[1]}]")
        end
      when "store"
        return nil unless args.size == 3
        PrintedExpr.new("#{args[0].enforce_parentheses}.store(#{args[1]}, #{args[2]})")
      end
    end

    # `Point.mk(3, 4)` and `p.x`, rather than the raw `Point(3, 4)` and `x(p)`. A
    # tuple's constructor is named after the sort and its accessors after the fields,
    # so it's the decls that get matched and not the names - the same reason
    # EnumExpr#value matches decls, since nothing stops a variable being called `x`.
    def format_tuple(a, args)
      decl = a.func_decl
      if a.sort.is_a?(TupleSort) and decl == a.sort.constructor
        return PrintedExpr.new("#{a.sort}.mk(#{args.join(", ")})")
      end
      return nil unless args.size == 1
      receiver_sort = a.arguments[0].sort
      return nil unless receiver_sort.is_a?(TupleSort)
      field = receiver_sort.accessors.key(decl)
      # A method call binds tighter than any operator, so only the receiver can need
      # parentheses and the result is atomic
      field && PrintedExpr.new("#{args[0].enforce_parentheses}.#{field}")
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

        # A lone `seq.unit` where Ruby's Array takes a bare element prints as that element
        SEQ_ELEMENT_ARGS.fetch(name, []).each do |i|
          arg = a.arguments[i]
          args[i] = format_ast(arg.arguments[0]) if arg and seq_unit?(arg)
        end

        # String and Char values are indexed decls - `(_ String "abc")` and `(_ Char 97)` -
        # so `decl.name` is just "String"/"Char", and the value is a decl parameter.
        if string_value?(decl)
          return PrintedExpr.new(LowLevel.get_string(a).inspect)
        end
        if char_value?(decl)
          return PrintedExpr.new("Char(#{[decl.parameter(0)].pack("U").inspect})")
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

        # Before the zero-argument case below, since `set.empty` is one of these
        finite_set = format_finite_set(a, name, args)
        return finite_set if finite_set

        # Set operations come back from models as `(_ map and)`, `(_ map or)` etc.
        # `decl.name` is just "map" for all of them, the mapped function is a decl parameter.
        if name == "map" and decl.num_parameters == 1 and decl.parameter_kind(0) == :func_decl
          return PrintedExpr.new("map(#{decl.func_decl_parameter(0).name}, #{args.join(", ")})")
        end

        array = format_array(a, name, args)
        return array if array

        tuple = format_tuple(a, args)
        return tuple if tuple

        pseudo_boolean = format_pseudo_boolean(a, name, args)
        return pseudo_boolean if pseudo_boolean

        # Before the zero-argument case below, since `re.none` / `re.all` /
        # `re.allchar` are three of these
        re = format_re(a, name, args)
        return re if re

        return PrintedExpr.new(name, false) if args.size == 0

        # Operations which read best in Ruby as a method call on their first argument
        method_call = format_method_call(name, args)
        return method_call if method_call

        # ...and the ones where the receiver is the second argument instead
        flipped_call = format_flipped_method_call(name, args)
        return flipped_call if flipped_call

        # ...and the map/fold family, where it's the last one
        map_fold = format_seq_map_fold(name, args)
        return map_fold if map_fold

        index = format_index(a, name, args)
        return index if index

        if OPERATOR_NAMES[name] and args.size == 2
          return PrintedExpr.new("#{args[0].enforce_parentheses} #{OPERATOR_NAMES[name]} #{args[1].enforce_parentheses}", true)
        end

        # Special case common Bitvec operators
        case name
        # All one-argument decls carrying a single int parameter. `repeat`, `int_to_bv`,
        # `bit2bool` and `divisible` were printing without theirs, which made
        # `u.bit(0)` and `u.bit(7)`, or `x.divisible_by?(3)` and `x.divisible_by?(5)`,
        # the same string.
        when "rotate_left", "rotate_right", "zero_extend", "sign_extend",
             "repeat", "int_to_bv", "bit2bool", "divisible"
          if args.size == 1
            n = Z3::LowLevel.get_decl_int_parameter(a.func_decl, 0)
            return PrintedExpr.new("#{name}(#{args[0]}, #{n})", true)
          end
        # Same again, except these take a rounding mode first, so the size is the
        # decl parameter of a two-argument application. The float *sources* -
        # `to_fp` and friends - deliberately aren't here: their parameters are the
        # result sort, which `#sort` answers, the way `NaN` prints without its.
        when "fp.to_sbv", "fp.to_ubv"
          if args.size == 2
            n = Z3::LowLevel.get_decl_int_parameter(a.func_decl, 0)
            return PrintedExpr.new("#{name}(#{args[0]}, #{args[1]}, #{n})", true)
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
