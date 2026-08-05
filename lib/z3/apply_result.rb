module Z3
  # What a Tactic made of a Goal: the subgoals it broke that goal into.
  #
  # The original goal is satisfiable exactly when one of the subgoals is, so no
  # subgoals at all means the tactic decided the goal is unsatisfiable, and a single
  # subgoal which is `decided_sat?` means it decided the other way.
  class ApplyResult
    include ReferenceCounted
    include Enumerable

    attr_reader :_apply_result
    def initialize(_apply_result)
      @_apply_result = _apply_result
      inc_ref! :apply_result, _apply_result
    end

    def size
      LowLevel.apply_result_get_num_subgoals(self)
    end

    def [](num)
      raise Z3::Exception, "Out of range" unless num.between?(0, size-1)
      Goal.from_pointer(LowLevel.apply_result_get_subgoal(self, num))
    end

    def each
      return to_enum(:each) unless block_given?
      size.times { |i| yield self[i] }
      self
    end

    def to_s
      LowLevel.apply_result_to_string(self)
    end

    def inspect
      "Z3::ApplyResult<#{size} subgoal#{"s" unless size == 1}>"
    end
  end
end
