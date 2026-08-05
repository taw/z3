module Z3
  # Incremental preprocessing for a Solver.
  #
  # Where a Tactic transforms a Goal into subgoals you can look at, a Simplifier has
  # nothing you can apply it to - attaching it to a solver with `Solver#with_simplifier`
  # is the only way to use one - and `#and_then` is its only combinator.
  class Simplifier
    include ReferenceCounted

    # Simplifiers we refuse to build, because Z3 gets them wrong. Pinned down in
    # `spec/upstream_bugs_spec.rb`, which reaches past this class to reproduce the bug -
    # when that spec starts failing, Z3 has fixed it and the entry here can go.
    UNSOUND = {
      "elim-unconstrained" =>
        "it drops variables it decides are unconstrained without ever rebuilding them, " \
        "so the solver answers :sat with a model which doesn't satisfy the assertions",
    }

    attr_reader :_simplifier
    # Takes either a simplifier name, or a pointer from the low level API
    def initialize(_simplifier)
      case _simplifier
      when String
        names = Simplifier.names
        raise Z3::Exception, "#{_simplifier} not on list of known simplifiers, available: #{names.join(" ")}" unless names.include?(_simplifier)
        if (reason = UNSOUND[_simplifier])
          raise Z3::Exception, "#{_simplifier} is unsound in Z3 #{Z3.version} - #{reason}"
        end
        _simplifier = LowLevel.mk_simplifier(_simplifier)
      when FFI::Pointer
        # Nothing to do
      else
        raise Z3::Exception, "Simplifier name or pointer expected, got #{_simplifier.class}"
      end
      @_simplifier = _simplifier
      inc_ref! :simplifier, _simplifier
    end

    def help
      LowLevel.simplifier_get_help(self)
    end

    # The only combinator Z3 gives simplifiers - there's no or_else, cond, or repeat
    # the way there is for Tactic, because a simplifier can't fail
    def and_then(other)
      raise Z3::Exception, "Simplifier required" unless other.is_a?(Simplifier)
      Simplifier.new LowLevel.simplifier_and_then(self, other)
    end

    # `Z3_simplifier_get_param_descrs` lists every parameter the simplifier takes,
    # `#help` describes them
    def param_descrs
      ParamDescrs.new(LowLevel.simplifier_get_param_descrs(self))
    end

    # Simplifiers are immutable, so this is a new one with the parameters baked into it
    # rather than a change to this one
    def using_params(params)
      params = Params.new(params, param_descrs) unless params.is_a?(Params)
      Simplifier.new LowLevel.simplifier_using_params(self, params)
    end

    class << self
      # Z3's whole list, including anything in UNSOUND - #named is where those get
      # turned down, so this stays a faithful report of what Z3 has
      def names
        (0...LowLevel.get_num_simplifiers).map{|i| LowLevel.get_simplifier_name(i) }
      end

      def description(name)
        raise Z3::Exception, "#{name} not on list of known simplifiers, available: #{names.join(" ")}" unless names.include?(name)
        LowLevel.simplifier_get_descr(name)
      end

      def named(str)
        new str
      end
    end
  end
end
