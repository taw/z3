module Z3
  class Probe
    attr_reader :_probe
    def initialize(_probe)
      @_probe = _probe
      LowLevel.probe_inc_ref(self)
    end

    def &(other)
      raise Z3::Exception, "Probe required" unless other.is_a?(Probe)
      Probe.new LowLevel.probe_and(self, other)
    end

    def |(other)
      raise Z3::Exception, "Probe required" unless other.is_a?(Probe)
      Probe.new LowLevel.probe_or(self, other)
    end

    def ~
      Probe.new LowLevel.probe_not(self)
    end

    def !
      Probe.new LowLevel.probe_not(self)
    end

    def ==(other)
      raise Z3::Exception, "Probe required" unless other.is_a?(Probe)
      Probe.new LowLevel.probe_eq(self, other)
    end

    def >=(other)
      raise Z3::Exception, "Probe required" unless other.is_a?(Probe)
      Probe.new LowLevel.probe_ge(self, other)
    end

    def >(other)
      raise Z3::Exception, "Probe required" unless other.is_a?(Probe)
      Probe.new LowLevel.probe_gt(self, other)
    end

    def <=(other)
      raise Z3::Exception, "Probe required" unless other.is_a?(Probe)
      Probe.new LowLevel.probe_le(self, other)
    end

    def <(other)
      raise Z3::Exception, "Probe required" unless other.is_a?(Probe)
      Probe.new LowLevel.probe_lt(self, other)
    end

    def apply(goal)
      raise Z3::Exception, "Goal required" unless goal.is_a?(Goal)
      LowLevel.probe_apply(self, goal)
    end

    class <<self
      def const(num)
        raise Z3::Exception, "Number required" unless num.is_a?(Numeric)
        new LowLevel.probe_const(num.to_f)
      end

      def names
        (0...LowLevel.get_num_probes).map{|i| LowLevel.get_probe_name(i) }
      end

      def named(str)
        raise Z3::Exception, "#{str} not on list of known probes, available: #{names.join(" ")}" unless names.include?(str)
        new LowLevel.mk_probe(str)
      end
    end
  end
end
