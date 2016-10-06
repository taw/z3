module Z3
  class Goal
    attr_reader :_goal
    def initialize(_goal)
      @_goal = _goal
    end

    def assert(ast)
      raise Z3::Exception, "AST required" unless ast.is_a?(AST)
      LowLevel.goal_assert(self, ast)
    end

    def reset
      LowLevel.goal_reset(self)
    end

    def depth
      LowLevel.goal_depth(self)
    end

    def size
      LowLevel.goal_size(self)
    end

    def num_exprs
      LowLevel.goal_num_exprs(self)
    end

    def precision
      LowLevel.goal_precision(self)
    end

    def inconsistent?
      # Does it convert bool or do we need to ?
      LowLevel.goal_inconsistent(self)
    end

    def decided_sat?
      # Does it convert bool or do we need to ?
      LowLevel.goal_is_decided_sat(self)
    end

    def decided_unsat?
      # Does it convert bool or do we need to ?
      LowLevel.goal_is_decided_unsat(self)
    end

    def formula(num)
      raise Z3::Exception, "Out of range" unless num.between?(0, size-1)
      # We should probably deal with out of bounds here
      Expr.new_from_pointer(LowLevel.goal_formula(self, num))
    end

    def to_s
      LowLevel.goal_to_string(self)
    end

    class << self
      def new(models=false, unsat_cores=false, proofs=false)
        super LowLevel.mk_goal(!!models, !!unsat_cores, !!proofs)
      end
    end
  end
end
