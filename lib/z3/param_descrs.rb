module Z3
  # Which parameters a Solver, Optimize, or Tactic accepts, and what type each of them is.
  #
  # Z3 validates parameters against these, but only once it starts solving, and it
  # reports failures as a bare Z3_EXCEPTION. Params checks names and types against
  # this upfront so a typo fails where it was made.
  class ParamDescrs
    include ReferenceCounted

    # Z3_param_kind. :other is for parameters Z3 has no specific type for,
    # :invalid means there is no such parameter at all.
    KINDS = {
      0 => :uint,
      1 => :bool,
      2 => :double,
      3 => :symbol,
      4 => :string,
      5 => :other,
      6 => :invalid,
    }

    attr_reader :_param_descrs
    def initialize(_param_descrs)
      @_param_descrs = _param_descrs
      inc_ref! :param_descrs, _param_descrs
    end

    def size
      LowLevel.param_descrs_size(self)
    end

    def names
      (0...size).map do |i|
        LowLevel.get_symbol_string(LowLevel.param_descrs_get_name(self, i))
      end
    end

    def kind(name)
      k = LowLevel.param_descrs_get_kind(self, LowLevel.mk_string_symbol(name.to_s))
      KINDS.fetch(k) { raise Z3::Exception, "Unknown parameter kind #{k}" }
    end

    def include?(name)
      kind(name) != :invalid
    end

    def to_s
      LowLevel.param_descrs_to_string(self)
    end

    def inspect
      "Z3::ParamDescrs<#{size} parameters>"
    end
  end
end
