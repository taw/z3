module Z3
  class BoolExpr < Expr
    def ~
      sort.new(LowLevel.mk_not(self))
    end

    def !
      sort.new(LowLevel.mk_not(self))
    end

    def &(other)
      Expr.And(self, other)
    end

    def |(other)
      Expr.Or(self, other)
    end

    def ^(other)
      Expr.Xor(self, other)
    end

    def iff(other)
      BoolExpr.Iff(self, other)
    end

    def implies(other)
      BoolExpr.Implies(self, other)
    end

    def ite(a, b)
      BoolExpr.IfThenElse(self, a, b)
    end

    # Z3_lbool - anything else is neither true nor false, so it has no Ruby value
    BOOL_VALUES = {1 => true, -1 => false}.freeze

    def to_b
      value = BOOL_VALUES[LowLevel.get_bool_value(self)]
      return value unless value.nil?
      value = BOOL_VALUES[LowLevel.get_bool_value(simplify)]
      raise Z3::Exception, "Can't convert expression #{to_s} into Boolean" if value.nil?
      value
    end

    # Every sort which can hand back a Ruby object spells it #value
    alias_method :value, :to_b

    public_class_method :new

    class << self
      def coerce_to_same_bool_sort(*args)
        args = coerce_to_same_sort(*args)
        raise Z3::Exception, "Bool value expected" unless args[0].is_a?(BoolExpr)
        args
      end

      def Implies(a,b)
        a, b = coerce_to_same_bool_sort(a, b)
        BoolSort.new.new(LowLevel.mk_implies(a, b))
      end

      def Iff(a,b)
        a, b = coerce_to_same_bool_sort(a, b)
        BoolSort.new.new(LowLevel.mk_iff(a, b))
      end

      def IfThenElse(a, b, c)
        a, = coerce_to_same_bool_sort(a)
        b, c = coerce_to_same_sort(b, c)
        b.sort.new(LowLevel.mk_ite(a, b, c))
      end

      # Native cardinality constraint: at most k of the given Bool exprs are true.
      # An `expr => weight` Hash weighs them instead, so `AtMost({a => 3, b => 2}, 4)`
      # allows either one but not both.
      def AtMost(args, k)
        args, weights, k = pseudo_boolean_args(args, k)
        if weights
          BoolSort.new.new(LowLevel.mk_pble(args, weights, k))
        else
          BoolSort.new.new(LowLevel.mk_atmost(args, k))
        end
      end

      # Native cardinality constraint: at least k of the given Bool exprs are true,
      # or at least k units of weight when given an `expr => weight` Hash
      def AtLeast(args, k)
        args, weights, k = pseudo_boolean_args(args, k)
        if weights
          BoolSort.new.new(LowLevel.mk_pbge(args, weights, k))
        else
          BoolSort.new.new(LowLevel.mk_atleast(args, k))
        end
      end

      # Native cardinality constraint: exactly k of the given Bool exprs are true,
      # or exactly k units of weight when given an `expr => weight` Hash
      def Exactly(args, k)
        args, weights, k = pseudo_boolean_args(args, k)
        BoolSort.new.new(LowLevel.mk_pbeq(args, weights || [1] * args.size, k))
      end

      private

      # Coefficients and bounds are C ints, and FFI's own complaint about an
      # oversized one names neither the method nor the value
      INT_RANGE = (-2**31)...(2**31)

      # Two spellings of one constraint: a list counts how many of the exprs are true,
      # an `expr => weight` Hash adds up the weights of the true ones. Z3 normalises a
      # weighted constraint whose weights are all 1 back into the unweighted term, so
      # `AtMost([a, b], 1)` and `AtMost({a => 1, b => 1}, 1)` are not merely equivalent,
      # they're the same AST. Returns nil weights for the unweighted spelling, because
      # only Exactly has to make up the 1s (Z3 has no unweighted `pbeq`).
      def pseudo_boolean_args(args, k)
        weights = nil
        if args.is_a?(Hash)
          args, weights = args.keys, args.values
          weights.each do |weight|
            raise Z3::Exception, "Pseudo-boolean weights must be Integers, got #{weight.inspect}" unless weight.is_a?(Integer)
            raise Z3::Exception, "Pseudo-boolean weight #{weight} is too big for Z3, which counts in 32 bit ints" unless INT_RANGE.include?(weight)
          end
          # A weighted total can go negative, so unlike a count it has no natural floor
          raise Z3::Exception, "Pseudo-boolean bound must be an Integer" unless k.is_a?(Integer)
        else
          raise Z3::Exception, "Cardinality bound must be a non-negative Integer" unless k.is_a?(Integer) and k >= 0
        end
        raise Z3::Exception, "Cardinality bound #{k} is too big for Z3, which counts in 32 bit ints" unless INT_RANGE.include?(k)
        raise Z3::Exception, "Cardinality constraint requires at least one argument" if args.empty?
        [coerce_to_same_bool_sort(*args), weights, k]
      end
    end
  end
end
