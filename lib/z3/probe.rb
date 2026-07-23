module Z3
  class Probe
    include ReferenceCounted

    attr_reader :_probe
    # Takes either a probe name, or a pointer from the low level API
    def initialize(_probe)
      case _probe
      when String
        names = Probe.names
        raise Z3::Exception, "#{_probe} not on list of known probes, available: #{names.join(" ")}" unless names.include?(_probe)
        _probe = LowLevel.mk_probe(_probe)
      when FFI::Pointer
        # Nothing to do
      else
        raise Z3::Exception, "Probe name or pointer expected, got #{_probe.class}"
      end
      @_probe = _probe
      inc_ref! :probe, _probe
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

      def description(name)
        raise Z3::Exception, "#{name} not on list of known probes, available: #{names.join(" ")}" unless names.include?(name)
        LowLevel.probe_get_descr(name)
      end

      def named(str)
        new str
      end
    end
  end
end
