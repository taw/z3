module Z3
  class Goal
    include ReferenceCounted
    include Enumerable

    attr_reader :_goal
    def initialize(_goal)
      @_goal = _goal
      inc_ref! :goal, _goal
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

    # The formulas, which is what you need to get a goal back into a Solver - a
    # subgoal out of a Tactic is a new problem, and nothing else can solve it
    def each
      return to_enum(:each) unless block_given?
      size.times { |i| yield formula(i) }
      self
    end

    # A subgoal is a different problem to the one the tactic started with, so a model
    # of the subgoal isn't a model of the original goal. This converts one back,
    # undoing whatever the tactic did to get here. Only works if the goal was built
    # with models enabled.
    def convert_model(model)
      raise Z3::Exception, "Model required" unless model.is_a?(Model)
      Model.new(LowLevel.goal_convert_model(self, model))
    end

    def to_s
      LowLevel.goal_to_string(self)
    end

    def to_dimacs(include_names=true)
      LowLevel.goal_to_dimacs_string(self, include_names)
    end

    class << self
      def new(models=false, unsat_cores=false, proofs=false)
        super LowLevel.mk_goal(!!models, !!unsat_cores, !!proofs)
      end

      # ::new builds a fresh goal out of flags, so a goal which already exists -
      # a subgoal from ApplyResult - needs a way in of its own
      def from_pointer(_goal)
        goal = allocate
        goal.send(:initialize, _goal)
        goal
      end
    end
  end
end
