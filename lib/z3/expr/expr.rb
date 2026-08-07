module Z3
  class Expr < AST
    attr_reader :sort

    def initialize(_ast, sort)
      super(_ast)
      @sort = sort
      raise Z3::Exception, "Values must have AST kind numeral, app, or quantifier" unless [:numeral, :app, :quantifier].include?(ast_kind)
    end

    def inspect
      "#{sort.to_s}<#{to_s}>"
    end

    def ==(other)
      Expr.Eq(self, other)
    end

    def !=(other)
      Expr.Distinct(self, other)
    end

    # Ruby's coercion protocol, which is how `1 + int_var` and `1 < int_var` reach Z3
    # at all - Integer#+ and CompareHacks both hand the pair to the right-hand side to
    # convert. Both come back in the wider of the two sorts, so `1 + real_var` is
    # `(+ 1.0 r)` and not `(+ (to_real 1) r)`, and the Ruby value stays on the left
    # where it was written.
    #
    # Every Expr has it, not only the arithmetic ones. A sort which can't hold the
    # value raises here exactly what it raises with the operands the other way round,
    # which is the point of it being here - `1 == bool_var` and `bool_var == 1` are the
    # same question and shouldn't fail differently.
    def coerce(other)
      mine, theirs = Expr.coerce_to_same_sort(self, other)
      [theirs, mine]
    end

    # Rewrites the expression, replacing each key with its value. Keys are matched as
    # whole subterms, not just as variables, so `(a + b)` is as substitutable as `a`.
    #
    # Every replacement happens at once rather than one after another, so
    # `substitute(a => b, b => a)` swaps the two instead of turning every `a` into `b`.
    # A key which doesn't occur simply doesn't match anything, which is not an error.
    def substitute(replacements)
      raise Z3::Exception, "Hash of replacements required" unless replacements.is_a?(Hash)
      return self if replacements.empty?
      replacements.each_key do |from|
        raise Z3::Exception, "Can't substitute for #{AST.describe(from)}, only for exprs" unless from.is_a?(Expr)
      end
      # Z3 wants both sides of a replacement to have the same sort, so `to` is cast
      # towards `from` and not the other way round
      to = replacements.map { |from, replacement| from.sort.cast(replacement) }
      sort.new(LowLevel.substitute(self, replacements.keys, to))
    end

    # Inlines a function. Every application of a key is replaced by that key's value
    # with the arguments substituted in, so the function symbol disappears from the
    # term entirely - which is what turns a declared function plus a quantified axiom
    # into an ordinary quantifier-free expression.
    #
    #   f = Z3.Function("f", Int, Int)
    #   (f[a] + f[b]).substitute_functions(f => ->(x) { x * 2 })  # => (a * 2) + (b * 2)
    #
    # Where #substitute matches whole subterms, this matches on the *function symbol*,
    # so it reaches every application whatever the arguments - including applications
    # nested inside each other and ones under a quantifier.
    #
    # A value is normally a proc taking one argument per parameter of the function, in
    # the order they're declared. A `FuncDecl` of the same signature renames the
    # function, and any other value is what the function is replaced by everywhere,
    # arguments ignored.
    #
    # It's a separate method rather than a mode of #substitute because the two are
    # different Z3 calls and can't be made simultaneous with each other. Doing them in
    # sequence would make the result depend on which ran first, and #substitute
    # promises it doesn't.
    #
    # Replacements happen at once and are not applied to each other, exactly as in
    # #substitute. With `f => ->(x) { g[x] }, g => ->(x) { x * 7 }` an `f(a)` becomes
    # `g(a)` and stops there. A replacement which mentions its own function stops for
    # the same reason, so `f => ->(x) { f[x] + 1 }` terminates rather than unfolding
    # forever.
    def substitute_functions(replacements)
      raise Z3::Exception, "Hash of replacements required" unless replacements.is_a?(Hash)
      return self if replacements.empty?
      bodies = replacements.map do |decl, replacement|
        unless decl.is_a?(FuncDecl)
          # An Expr key is the easiest mistake to make here and has an exact answer
          extra = decl.is_a?(Expr) ? " - use #substitute to replace an expression" : ""
          raise Z3::Exception, "Can't substitute for #{AST.describe(decl)}, only for functions#{extra}"
        end
        # Z3 answers a nullary decl with a bare "invalid usage", and it's precisely the
        # case #substitute already covers
        raise Z3::Exception, "#{decl.name} is a constant, use #substitute for it" if decl.arity.zero?
        LowLevel.bound_body(*function_body(decl, replacement))
      end
      sort.new(LowLevel.substitute_funs(self, replacements.keys, bodies))
    end

    private

    # The variables the replacement is written in terms of, and the body it makes of
    # them. Fresh, so a proc which closes over a variable of the same name can't
    # capture the bound one by accident - the same reason SeqFunction uses them.
    #
    # Exactly one variable per parameter, always, which is what makes the arity
    # mistakes unreachable. Z3 takes a body over the wrong number of variables without
    # complaint and gets it wrong quietly in both directions: too few and the extra
    # arguments are dropped from the term, too many and a stray de Bruijn variable is
    # left in the result, to be met later as "Values must have AST kind numeral, app,
    # or quantifier" somewhere unrelated to the call that caused it.
    def function_body(decl, replacement)
      vars = decl.arity.times.map { |i| decl.domain(i).fresh_var("arg#{i}") }
      body = case replacement
      when Proc
        unless replacement.arity < 0 or replacement.arity == decl.arity
          raise Z3::Exception, "Replacement for #{decl.name} takes #{replacement.arity} argument#{"s" unless replacement.arity == 1}, expected #{decl.arity}"
        end
        replacement.call(*vars)
      when FuncDecl
        replacement[*vars]
      else
        replacement
      end
      [vars, decl.range.cast(body)]
    end

    class << self
      def coerce_to_same_sort(*args)
        # When coercion fails Ruby names the receiver's class - `1 + Object.new` says
        # "Object can't be coerced into Integer" - and the first Expr is the nearest
        # thing to a receiver we have. There may be none, in which case nothing was
        # being coerced towards anything and #sort_for_const says so instead.
        toward = args.find { |a| a.is_a?(Expr) }&.sort
        sorts = args.map { |a| a.is_a?(Expr) ? a.sort : Expr.sort_for_const(a, toward: toward) }
        # Sorts are only partially ordered, and #max answers an unordered pair with a
        # bare ArgumentError naming Ruby classes - which says nothing whatsoever when
        # both sides are EnumSorts. Folding by hand lets the sorts name themselves.
        max_sort = sorts.reduce do |a, b|
          comparison = (a <=> b) or raise ArgumentError, "Can't convert #{b} into #{a}"
          comparison >= 0 ? a : b
        end
        args.map do |a|
          max_sort.cast(a)
        end
      end

      # `toward` is the sort the value was being coerced towards, when there is one -
      # it only changes how a failure is worded
      def sort_for_const(a, toward: nil)
        # A Symbol is an enum value and nothing else, and it has no sort of its own.
        # Two enums are free to use the same value name, so the only thing that says
        # which enum `:red` belongs to is the sort on the other side of the operation.
        if a.is_a?(Symbol)
          return toward if toward.is_a?(EnumSort)
          # With no enum anywhere in sight there's nothing to resolve it against -
          # `Z3.Const(:red)` can't know whether that's a Color or a Squirrel. Falling
          # through would say "No Z3 sort for :red", which is true but unhelpful.
          raise Z3::Exception, "Can't tell which enum #{a.inspect} belongs to, ask the sort for it instead - `enum_sort[#{a.inspect}]`" unless toward
        end
        # An Array or a Hash is a tuple's fields, and like a Symbol it has no sort of
        # its own - `[3, 4]` is a Point only because that's what it's being compared
        # to. Anywhere else they're still not values, and fall through to the error.
        return toward if (a.is_a?(Array) or a.is_a?(Hash)) and toward.is_a?(TupleSort)
        case a
        when TrueClass, FalseClass
          BoolSort.new
        when Integer
          IntSort.new
        when Float, Rational
          RealSort.new
        # Ruby has no character type, so Strings are Strings - `char_var == "a"` is a sort
        # mismatch, and `CharSort.new.from_const("a")` is the way to say that
        when String
          StringSort.new
        else
          raise Z3::Exception, "#{AST.describe(a)} can't be coerced into #{toward}" if toward
          raise Z3::Exception, "No Z3 sort for #{AST.describe(a)}"
        end
      end

      # Turns `s[a..b]` into the offset and length that `str.substr` / `seq.extract`
      # want, with an open end meaning "to the end" - so the size is passed in rather
      # than recomputed. Two literal ends stay Ruby Integers all the way through, so
      # `s[2..4]` builds `(str.substr s 2 3)` rather than `(str.substr s 2 (+ (- 4 2) 1))`.
      #
      # Either end is an offset and nothing else, negative or not - see StringExpr#[]
      # for why Ruby's count-from-the-end isn't emulated.
      #
      # It lives here rather than on StringExpr or SeqExpr because both need it and
      # neither is the other's ancestor - and unlike everything else those two share,
      # this is Ruby arithmetic, not a Z3 call.
      def offset_and_length(range, size)
        offset = range.begin || 0
        return [offset, size - offset] if range.end.nil?
        last = range.end
        # Ruby has no `-` taking an Expr on the right, so a literal end above a
        # symbolic offset is the one pair that has to go to Z3. The other way round
        # doesn't - IntExpr#- takes an Integer.
        last = IntSort.new.cast(last) if last.is_a?(Integer) and !offset.is_a?(Integer)
        # An open beginning is offset 0, and subtracting it would only clutter the term
        len = (offset.is_a?(Integer) and offset.zero?) ? last : last - offset
        [offset, range.exclude_end? ? len : len + 1]
      end

      def new_from_pointer(_ast)
        _sort = Z3::VeryLowLevel.Z3_get_sort(Z3::LowLevel._ctx_pointer, _ast)
        Sort.from_pointer(_sort).new(_ast)
      end

      def Gt(a, b)
        a, b = coerce_to_same_sort(a, b)
        case a
        when ArithExpr
          BoolSort.new.new(LowLevel.mk_gt(a, b))
        when BitvecExpr
          raise Z3::Exception, "Use #signed_gt or #unsigned_gt for Bitvec, not >"
        else
          raise Z3::Exception, "Can't compare #{a.sort} values"
        end
      end

      def Ge(a, b)
        a, b = coerce_to_same_sort(a, b)
        case a
        when ArithExpr
          BoolSort.new.new(LowLevel.mk_ge(a, b))
        when BitvecExpr
          raise Z3::Exception, "Use #signed_ge or #unsigned_ge for Bitvec, not >="
        else
          raise Z3::Exception, "Can't compare #{a.sort} values"
        end
      end

      def Lt(a, b)
        a, b = coerce_to_same_sort(a, b)
        case a
        when ArithExpr
          BoolSort.new.new(LowLevel.mk_lt(a, b))
        when BitvecExpr
          raise Z3::Exception, "Use #signed_lt or #unsigned_lt for Bitvec, not <"
        else
          raise Z3::Exception, "Can't compare #{a.sort} values"
        end
      end

      def Le(a, b)
        a, b = coerce_to_same_sort(a, b)
        case a
        when ArithExpr
          BoolSort.new.new(LowLevel.mk_le(a, b))
        when BitvecExpr
          raise Z3::Exception, "Use #signed_le or #unsigned_le for Bitvec, not <="
        else
          raise Z3::Exception, "Can't compare #{a.sort} values"
        end
      end

      def Eq(a, b)
        a, b = coerce_to_same_sort(a, b)
        BoolSort.new.new(LowLevel.mk_eq(a, b))
      end

      def Distinct(*args)
        args = coerce_to_same_sort(*args)
        BoolSort.new.new(LowLevel.mk_distinct(args))
      end

      def And(*args)
        raise Z3::Exception, "And requires at least one argument" if args.empty?
        args = coerce_to_same_sort(*args)
        case args[0]
        when BoolExpr
          BoolSort.new.new(Z3::LowLevel.mk_and(args))
        when BitvecExpr
          args.inject do |a, b|
            a.sort.new(Z3::LowLevel.mk_bvand(a, b))
          end
        else
          raise Z3::Exception, "Can't perform logic operations on #{args[0].sort} exprs, only Bool and Bitvec"
        end
      end

      def Or(*args)
        raise Z3::Exception, "Or requires at least one argument" if args.empty?
        args = coerce_to_same_sort(*args)
        case args[0]
        when BoolExpr
          BoolSort.new.new(Z3::LowLevel.mk_or(args))
        when BitvecExpr
          args.inject do |a, b|
            a.sort.new(Z3::LowLevel.mk_bvor(a, b))
          end
        else
          raise Z3::Exception, "Can't perform logic operations on #{args[0].sort} exprs, only Bool and Bitvec"
        end
      end

      def Xor(*args)
        raise Z3::Exception, "Xor requires at least one argument" if args.empty?
        args = coerce_to_same_sort(*args)
        case args[0]
        when BoolExpr
          args.inject do |a, b|
            BoolSort.new.new(Z3::LowLevel.mk_xor(a, b))
          end
        when BitvecExpr
          args.inject do |a, b|
            a.sort.new(Z3::LowLevel.mk_bvxor(a, b))
          end
        else
          raise Z3::Exception, "Can't perform logic operations on #{args[0].sort} exprs, only Bool and Bitvec"
        end
      end

      def Add(*args)
        raise Z3::Exception, "Add requires at least one argument" if args.empty?
        args = coerce_to_same_sort(*args)
        case args[0]
        when ArithExpr
          args[0].sort.new(LowLevel.mk_add(args))
        when BitvecExpr
          args.inject do |a, b|
            a.sort.new(LowLevel.mk_bvadd(a, b))
          end
        else
          raise Z3::Exception, "Can't perform logic operations on #{args[0].sort} exprs, only Int/Real/Bitvec"
        end
      end

      def Sub(*args)
        raise Z3::Exception, "Sub requires at least one argument" if args.empty?
        args = coerce_to_same_sort(*args)
        case args[0]
        when ArithExpr
          args[0].sort.new(LowLevel.mk_sub(args))
        when BitvecExpr
          args.inject do |a, b|
            a.sort.new(LowLevel.mk_bvsub(a, b))
          end
        else
          raise Z3::Exception, "Can't perform logic operations on #{args[0].sort} values, only Int/Real/Bitvec"
        end
      end

      def Mul(*args)
        raise Z3::Exception, "Mul requires at least one argument" if args.empty?
        args = coerce_to_same_sort(*args)
        case args[0]
        when ArithExpr
          args[0].sort.new(LowLevel.mk_mul(args))
        when BitvecExpr
          args.inject do |a, b|
            a.sort.new(LowLevel.mk_bvmul(a, b))
          end
        else
          raise Z3::Exception, "Can't perform logic operations on #{args[0].sort} values, only Int/Real/Bitvec"
        end
      end

      # Quantifiers bind ordinary variables rather than de Bruijn indices - you pass
      # the same `Z3.Int("x")` you built the body out of, and Z3 rebinds it inside.
      # The variable goes on meaning the outer one everywhere else.
      def ForAll(bound, body)
        bound = bound_variables(bound)
        BoolSort.new.new(LowLevel.mk_forall_const(bound, BoolSort.new.cast(body)))
      end

      def Exists(bound, body)
        bound = bound_variables(bound)
        BoolSort.new.new(LowLevel.mk_exists_const(bound, BoolSort.new.cast(body)))
      end

      # An anonymous function. Z3 hands it back as an Array, so it indexes with `[]`
      # like any other - `Z3.Lambda(x, x * 2)[3]` is 6.
      #
      # One bound variable only: two would make an `Array(Int, Int, Int)`, and this
      # gem has no sort for n-ary arrays - `Sort.from_pointer` would report it as
      # `Array(Int, Int)` and indexing it would fail inside Z3.
      def Lambda(bound, body)
        bound = bound_variables(bound)
        raise Z3::Exception, "Lambda takes one bound variable, got #{bound.size}" unless bound.size == 1
        body = sort_for_const(body).from_const(body) unless body.is_a?(Expr)
        ArraySort.new(bound[0].sort, body.sort).new(LowLevel.mk_lambda_const(bound, body))
      end

      private

      # Bound variables have to be variables - `Z3.Int("x")`, not `x + 1` and not a
      # literal. Z3 says only "invalid argument" about the difference.
      def bound_variables(bound)
        bound = [bound] unless bound.is_a?(Array)
        raise Z3::Exception, "Quantifier needs at least one bound variable" if bound.empty?
        bound.each do |var|
          unless var.is_a?(Expr) and var.ast_kind == :app and var.func_decl.arity == 0 and var.func_decl.num_parameters == 0
            raise Z3::Exception, "Bound variables must be variables, got #{AST.describe(var)}"
          end
        end
        # Z3 takes a repeat and quietly renames the second to `x!1`, which shadows the
        # first - so the quantifier binds something the body can't be talking about
        raise Z3::Exception, "Bound variables must be distinct" unless bound.uniq.size == bound.size
        bound
      end
    end

  end
end
