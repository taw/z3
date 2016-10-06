module Z3
  class Tactic
    attr_reader :tactic
    def initialize(_tactic)
      @_tactic = _tactic
    end

    def help
      LowLevel.tactic_get_help(self)
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
