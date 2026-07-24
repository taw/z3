module Z3
  # A set of parameters for a Solver, Optimize, or Tactic.
  #
  # Z3 has no way to read parameters back, so this only ever accumulates - setting
  # the same name twice overrides it, and there's no way to unset one.
  #
  # If `descrs` is given, names and types are checked against it as they're set.
  # Solver and Optimize always pass theirs, because Z3 itself only notices a bad
  # parameter in the middle of solving, and then all it says is Z3_EXCEPTION.
  class Params
    include ReferenceCounted

    attr_reader :_params, :descrs
    def initialize(values = {}, descrs = nil)
      @_params = LowLevel.mk_params
      inc_ref! :params, @_params
      @descrs = descrs
      values.each do |name, value|
        self[name] = value
      end
    end

    def []=(name, value)
      sym = LowLevel.mk_string_symbol(name.to_s)
      case kind_for(name, value)
      when :uint
        LowLevel.params_set_uint(self, sym, value)
      when :bool
        LowLevel.params_set_bool(self, sym, value)
      when :double
        LowLevel.params_set_double(self, sym, value.to_f)
      when :symbol
        LowLevel.params_set_symbol(self, sym, LowLevel.mk_string_symbol(value.to_s))
      end
      value
    end

    def to_s
      LowLevel.params_to_string(self)
    end

    private

    # Which Z3_params_set_* to call. When we know what Z3 expects we go by that,
    # so an Integer is fine for a double parameter. Otherwise the Ruby value is
    # all we have to go on.
    def kind_for(name, value)
      kind = descrs ? declared_kind(name) : inferred_kind(name, value)
      unless valid_value?(kind, value)
        raise Z3::Exception, "Parameter `#{name}' expects #{kind}, got #{value.inspect}"
      end
      kind
    end

    def declared_kind(name)
      case kind = descrs.kind(name)
      when :invalid
        raise Z3::Exception, "Unknown parameter `#{name}'"
      when :uint, :bool, :double, :symbol
        kind
      else
        # :string parameters would need Z3_params_set_string, which takes a char*
        # Z3 never frees, so it's not in the FFI layer
        raise Z3::Exception, "Parameter `#{name}' has type #{kind}, which this API can't set"
      end
    end

    def inferred_kind(name, value)
      case value
      when true, false
        :bool
      when Integer
        :uint
      when Numeric
        :double
      when String, Symbol
        :symbol
      else
        raise Z3::Exception, "Can't use #{value.inspect} as value of parameter `#{name}'"
      end
    end

    def valid_value?(kind, value)
      case kind
      when :uint
        value.is_a?(Integer) and value >= 0 and value < 2**32
      when :bool
        value == true or value == false
      when :double
        value.is_a?(Numeric)
      when :symbol
        value.is_a?(String) or value.is_a?(Symbol)
      end
    end
  end
end
