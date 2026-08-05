module Z3
  class Tactic
    include ReferenceCounted

    attr_reader :_tactic
    # Takes either a tactic name, or a pointer from the low level API
    def initialize(_tactic)
      case _tactic
      when String
        names = Tactic.names
        raise Z3::Exception, "#{_tactic} not on list of known tactics, available: #{names.join(" ")}" unless names.include?(_tactic)
        _tactic = LowLevel.mk_tactic(_tactic)
      when FFI::Pointer
        # Nothing to do
      else
        raise Z3::Exception, "Tactic name or pointer expected, got #{_tactic.class}"
      end
      @_tactic = _tactic
      inc_ref! :tactic, _tactic
    end

    def help
      LowLevel.tactic_get_help(self)
    end

    # Runs the tactic, turning the goal into the subgoals which replace it - see
    # ApplyResult. The goal itself is left alone.
    def apply(goal, params = {})
      raise Z3::Exception, "Goal required" unless goal.is_a?(Goal)
      # Skipped for the common no-parameters case, as building a Params has to build
      # the parameter descriptions to check against
      return ApplyResult.new(LowLevel.tactic_apply(self, goal)) if params == {}
      params = Params.new(params, param_descrs) unless params.is_a?(Params)
      ApplyResult.new(LowLevel.tactic_apply_ex(self, goal, params))
    end

    # `Z3_tactic_get_param_descrs` lists every parameter the tactic takes,
    # `#help` describes them
    def param_descrs
      ParamDescrs.new(LowLevel.tactic_get_param_descrs(self))
    end

    # Tactics are immutable, so this is a new tactic with the parameters baked into
    # it rather than a change to this one
    def using_params(params)
      params = Params.new(params, param_descrs) unless params.is_a?(Params)
      Tactic.new LowLevel.tactic_using_params(self, params)
    end

    def or_else(other)
      raise Z3::Exception, "Tactic required" unless other.is_a?(Tactic)
      Tactic.new LowLevel.tactic_or_else(self, other)
    end

    def and_then(other)
      raise Z3::Exception, "Tactic required" unless other.is_a?(Tactic)
      Tactic.new LowLevel.tactic_and_then(self, other)
    end

    def parallel_and_then(other)
      raise Z3::Exception, "Tactic required" unless other.is_a?(Tactic)
      Tactic.new LowLevel.tactic_par_and_then(self, other)
    end

    def repeat(num)
      raise Z3::Exception, "Nonnegative Integer required" unless num.is_a?(Integer) and num >= 0
      Tactic.new LowLevel.tactic_repeat(self, num)
    end

    def try_for(time_ms)
      raise Z3::Exception, "Nonnegative Integer required" unless time_ms.is_a?(Integer) and time_ms >= 0
      Tactic.new LowLevel.tactic_try_for(self, time_ms)
    end

    class << self
      def names
        (0...LowLevel.get_num_tactics).map{|i| LowLevel.get_tactic_name(i) }
      end

      def description(name)
        raise Z3::Exception, "#{name} not on list of known tactics, available: #{names.join(" ")}" unless names.include?(name)
        LowLevel.tactic_get_descr(name)
      end

      def named(str)
        new str
      end

      # Runs them all in parallel and takes the first which doesn't fail - the
      # parallel #or_else, as #parallel_and_then is to #and_then
      def par_or(*tactics)
        raise Z3::Exception, "At least one tactic required" if tactics.empty?
        tactics.each do |tactic|
          raise Z3::Exception, "Tactic required" unless tactic.is_a?(Tactic)
        end
        new LowLevel.tactic_par_or(tactics)
      end

      def fail
        new LowLevel.tactic_fail
      end

      def fail_if(probe)
        raise Z3::Exception, "Prope required" unless probe.is_a?(Probe)
        new LowLevel.tactic_fail_if(probe)
      end

      def fail_if_not_decided
        new LowLevel.tactic_fail_if_not_decided
      end

      def skip
        new LowLevel.tactic_skip
      end

      def when(probe, tactic)
        raise Z3::Exception, "Prope required" unless probe.is_a?(Probe)
        raise Z3::Exception, "Tactic required" unless tactic.is_a?(Tactic)
        new LowLevel.tactic_when(probe, tactic)
      end

      def cond(probe, tactic1, tactic2)
        raise Z3::Exception, "Prope required" unless probe.is_a?(Probe)
        raise Z3::Exception, "Tactic required" unless tactic1.is_a?(Tactic)
        raise Z3::Exception, "Tactic required" unless tactic2.is_a?(Tactic)
        new LowLevel.tactic_cond(probe, tactic1, tactic2)
      end
    end
  end
end
