module Z3
  class Expr < AST
    attr_reader :sort
    def initialize(_ast, sort)
      super(_ast)
      @sort = sort
      raise Z3::Exception, "Values must have AST kind numeral or app" unless [:numeral, :app].include?(ast_kind)
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

    class << self
      def coerce_to_same_sort(*args)
        # This will raise exception unless one of the sorts is highest
        max_sort = args.map{|a| a.is_a?(Expr) ? a.sort : Expr.sort_for_const(a)}.max
        args.map do |a|
          max_sort.cast(a)
        end
      end

      def sort_for_const(a)
        case a
        when TrueClass, FalseClass
          BoolSort.new
        when Integer
          IntSort.new
        when Float
          RealSort.new
        else
          raise Z3::Exception, "No idea how to autoconvert `#{a.class}': `#{a.inspect}'"
        end
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
        args = coerce_to_same_sort(*args)
        case args[0]
        when BoolExpr
          BoolSort.new.new(Z3::LowLevel.mk_and(args))
        when BitvecExpr
          args.inject do |a,b|
            a.sort.new(Z3::LowLevel.mk_bvand(a, b))
          end
        else
          raise Z3::Exception, "Can't perform logic operations on #{a.sort} exprs, only Bool and Bitvec"
        end
      end

      def Or(*args)
        args = coerce_to_same_sort(*args)
        case args[0]
        when BoolExpr
          BoolSort.new.new(Z3::LowLevel.mk_or(args))
        when BitvecExpr
          args.inject do |a,b|
            a.sort.new(Z3::LowLevel.mk_bvor(a, b))
          end
        else
          raise Z3::Exception, "Can't perform logic operations on #{a.sort} exprs, only Bool and Bitvec"
        end
      end

      def Xor(*args)
        args = coerce_to_same_sort(*args)
        case args[0]
        when BoolExpr
          args.inject do |a,b|
            BoolSort.new.new(Z3::LowLevel.mk_xor(a, b))
          end
        when BitvecExpr
          args.inject do |a,b|
            a.sort.new(Z3::LowLevel.mk_bvxor(a, b))
          end
        else
          raise Z3::Exception, "Can't perform logic operations on #{a.sort} exprs, only Bool and Bitvec"
        end
      end

      def Add(*args)
        raise Z3::Exception if args.empty?
        args = coerce_to_same_sort(*args)
        case args[0]
        when ArithExpr
          args[0].sort.new(LowLevel.mk_add(args))
        when BitvecExpr
          args.inject do |a,b|
            a.sort.new(LowLevel.mk_bvadd(a,b))
          end
        else
          raise Z3::Exception, "Can't perform logic operations on #{args[0].sort} exprs, only Int/Real/Bitvec"
        end
      end

      def Sub(*args)
        args = coerce_to_same_sort(*args)
        case args[0]
        when ArithExpr
          args[0].sort.new(LowLevel.mk_sub(args))
        when BitvecExpr
          args.inject do |a,b|
            a.sort.new(LowLevel.mk_bvsub(a,b))
          end
        else
          raise Z3::Exception, "Can't perform logic operations on #{args[0].sort} values, only Int/Real/Bitvec"
        end
      end

      def Mul(*args)
        args = coerce_to_same_sort(*args)
        case args[0]
        when ArithExpr
          args[0].sort.new(LowLevel.mk_mul(args))
        when BitvecExpr
          args.inject do |a,b|
            a.sort.new(LowLevel.mk_bvmul(a,b))
          end
        else
          raise Z3::Exception, "Can't perform logic operations on #{args[0].sort} values, only Int/Real/Bitvec"
        end
      end
    end
  end
end
