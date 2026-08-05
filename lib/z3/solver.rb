module Z3
  class Solver
    include ReferenceCounted

    attr_reader :_solver
    # `_solver` is how the alternative constructors below pass in their own solver;
    # `Solver.new` is the general purpose one and you almost always want it. `simple`
    # says which kind `_solver` is, because Z3 offers no way to ask one - see #simple?
    #
    # All three are positional on purpose: a keyword here would make Ruby read
    # `Solver.new(rlimit: 1)` as keywords rather than as the parameters Hash it is.
    def initialize(params = {}, _solver = LowLevel.mk_solver, simple = false)
      @simple = simple
      @_solver = _solver
      inc_ref! :solver, @_solver
      reset_model!
      # Skipped for the common no-parameters case, as #set_params has to build
      # the parameter descriptions to check against, and there are hundreds of them
      set_params(params) unless params == {}
    end

    class << self
      # `Solver.new` inspects the assertions and assembles a tactic to match them.
      # This one is just the incremental SMT core, which is usually weaker - but it's
      # the only solver which implements #trail.
      def simple(params = {})
        new(params, LowLevel.mk_simple_solver, true)
      end

      # Specializes the solver for one SMT-LIB2 logic ("QF_LIA", "QF_BV", ...), which
      # can be much faster, at the cost of raising on anything outside that logic.
      # Z3 rejects unknown names itself, we have no list to check against.
      def for_logic(logic, params = {})
        new(params, LowLevel.mk_solver_for_logic(LowLevel.mk_symbol(logic)))
      end

      # Every #check runs the tactic on the assertions. Tactics have no notion of
      # scopes, so #push / #pop are simulated by re-running everything.
      def from_tactic(tactic, params = {})
        raise Z3::Exception, "Tactic required" unless tactic.is_a?(Tactic)
        new(params, LowLevel.mk_solver_from_tactic(tactic))
      end
    end

    # Attaches a simplifier, which the solver then runs over the assertions as
    # incremental preprocessing.
    #
    # Z3 hands back a *different* solver rather than changing this one, so this returns
    # a new Solver and leaves the receiver alone - and it refuses outright once
    # anything has been asserted, so it has to come first. Parameters don't carry over
    # from the receiver either, as Z3 has no way to read them back.
    def with_simplifier(simplifier, params = {})
      raise Z3::Exception, "Simplifier required" unless simplifier.is_a?(Simplifier)
      # A simplifier is preprocessing bolted onto whatever this already is, so the
      # solver underneath is still the same kind - a simple one stays simple
      Solver.new(params, LowLevel.solver_add_simplifier(self, simplifier), simple?)
    end

    # Whether this is the plain incremental SMT core - `Solver.simple`, or a simplifier
    # bolted onto one - rather than a solver built out of tactics, which is what
    # `Solver.new`, `.for_logic` and `.from_tactic` all give.
    #
    # It matters because two Z3 features are implemented by that solver and no other:
    # #trail and #set_initial_value. Z3 won't say which kind a solver is, so this is
    # remembered from however it was built.
    def simple?
      @simple
    end

    # `Z3_solver_get_param_descrs` lists every parameter the solver takes,
    # `#help` describes them
    def param_descrs
      ParamDescrs.new(LowLevel.solver_get_param_descrs(self))
    end

    # Parameters accumulate - setting one twice overrides it, but parameters set
    # by earlier calls stay. Pass a Params if you want to skip the name and type
    # checks, a Hash if you don't.
    def set_params(params)
      params = Params.new(params, param_descrs) unless params.is_a?(Params)
      LowLevel.solver_set_params(self, params)
      self
    end

    def push
      reset_model!
      LowLevel.solver_push(self)
    end

    def pop(n=1)
      reset_model!
      LowLevel.solver_pop(self, n)
    end

    def reset
      reset_model!
      LowLevel.solver_reset(self)
    end

    def assert(ast)
      reset_model!
      LowLevel.solver_assert(self, ast)
    end

    # `tracker` is a Bool const standing in for `ast`, and it's what shows up in
    # #unsat_core if the solver blames this assertion
    def assert_and_track(ast, tracker)
      reset_model!
      LowLevel.solver_assert_and_track(self, ast, tracker)
    end

    # Assumptions are Bool exprs taken as true for this one check and nothing after
    # it - unlike #assert they leave no trace on the solver, so there's no #push /
    # #pop to pair up. They're also what #unsat_core blames, so an :unsat names the
    # assumptions responsible without any of #assert_and_track's tracker variables.
    def check(*assumptions)
      reset_model!
      result = check_sat_results(
        if assumptions.empty?
          LowLevel.solver_check(self)
        else
          LowLevel.solver_check_assumptions(self, coerce_assumptions(assumptions))
        end
      )
      @has_model = true if result == :sat
      result
    end

    def satisfiable?(*assumptions)
      case check(*assumptions)
      when :sat
        true
      when :unsat
        false
      else
        raise Z3::Exception, "Satisfiability unknown"
      end
    end

    def unsatisfiable?(*assumptions)
      case check(*assumptions)
      when :unsat
        true
      when :sat
        false
      else
        raise Z3::Exception, "Satisfiability unknown"
      end
    end

    def model
      if @has_model
        @model ||= Z3::Model.new(LowLevel.solver_get_model(self))
      else
        raise Z3::Exception, "You need to check that it's satisfiable before asking for the model"
      end
    end

    def assertions
      _ast_vector = LowLevel.solver_get_assertions(self)
      LowLevel.unpack_ast_vector(_ast_vector)
    end

    # Only the trackers passed to #assert_and_track can ever show up here,
    # plainly asserted formulas are never blamed
    def unsat_core
      _ast_vector = LowLevel.solver_get_unsat_core(self)
      LowLevel.unpack_ast_vector(_ast_vector)
    end

    # Everything about `variables` which follows from the assertions, as a list of
    # `assumption => literal` implications (`true => literal` for the ones which
    # hold outright). This solves, so it's much more work than #assertions.
    def consequences(variables, assumptions = [])
      reset_model!
      LowLevel.with_ast_vectors(assumptions, variables, []) do |_assumptions, _variables, _consequences|
        result = check_sat_results(LowLevel.solver_get_consequences(self, _assumptions, _variables, _consequences))
        raise Z3::Exception, "Consequences need satisfiable assertions, these are #{result}" unless result == :sat
        LowLevel.unpack_ast_vector(_consequences)
      end
    end

    # One case split, for divide-and-conquer solving - each call returns the next
    # cube, and `[false]` once they're exhausted (after which it starts over).
    # `variables` is which literals to split on, or [] to let Z3 choose.
    def cube(variables = [], backtrack_level = 0)
      reset_model!
      LowLevel.with_ast_vectors(variables) do |_variables|
        LowLevel.unpack_ast_vector(LowLevel.solver_cube(self, _variables, backtrack_level))
      end
    end

    # The assertions Z3 has boiled down to a single literal, and everything it
    # hasn't - together they're a partition of what the solver currently knows
    def units
      _ast_vector = LowLevel.solver_get_units(self)
      LowLevel.unpack_ast_vector(_ast_vector)
    end

    def non_units
      _ast_vector = LowLevel.solver_get_non_units(self)
      LowLevel.unpack_ast_vector(_ast_vector)
    end

    # The literals the solver currently has assigned, in assignment order.
    # Only Solver.simple implements it - every other kind raises Z3::Exception.
    def trail
      _ast_vector = LowLevel.solver_get_trail(self)
      LowLevel.unpack_ast_vector(_ast_vector)
    end

    # A hint at which value to try for a variable first - a warm start, for feeding a
    # known-good solution back in. It stays a hint: an impossible one is overridden
    # rather than believed, and it can't make an unsat problem sat. It survives #check
    # and #push / #pop, and setting it again replaces it.
    #
    # Only Solver.simple implements it. Every other kind takes the call and silently
    # ignores it, which is worse than refusing, so this refuses on their behalf.
    #
    # Z3 acts on it for Bool (the initial phase), Int and Real (the Simplex tableau is
    # calibrated towards it) and Bitvec (a phase per bit). Other sorts - String and Seq
    # among them - it accepts and ignores, and there's no way to be told which is which.
    def set_initial_value(var, value)
      unless simple?
        raise Z3::Exception, "Only Solver.simple takes initial values, every other solver ignores them"
      end
      unless var.is_a?(Expr) and var.ast_kind == :app and var.func_decl.arity == 0
        raise Z3::Exception, "Initial values are for variables, and #{var.inspect} is not one"
      end
      LowLevel.solver_set_initial_value(self, var, var.sort.cast(value))
      self
    end

    # Cancels a #check in progress, so it returns :unknown instead of an answer.
    # It's meant for another thread or a signal handler - on an idle solver it does
    # nothing, and the flag is cleared by the time the next #check starts.
    def interrupt
      LowLevel.solver_interrupt(self)
      self
    end

    # Parses SMT-LIB2 and adds its assertions on top of whatever's already asserted.
    # Anything it declares goes into the shared context, so `(declare-const a Int)`
    # here is the same variable as `Z3.Int("a")` in Ruby - but the parser starts with
    # an empty symbol table every time, so each string has to declare what it uses.
    def from_string(str)
      reset_model!
      LowLevel.solver_from_string(self, str)
      self
    end

    def from_file(path)
      reset_model!
      LowLevel.solver_from_file(self, path)
      self
    end

    def statistics
      _stats = LowLevel::solver_get_statistics(self)
      LowLevel.unpack_statistics(_stats)
    end

    def help
      LowLevel.solver_get_help(self)
    end

    def num_scopes
      LowLevel.solver_get_num_scopes(self)
    end

    def reason_unknown
      LowLevel.solver_get_reason_unknown(self)
    end

    def to_s
      LowLevel.solver_to_string(self)
    end

    def to_dimacs(include_names=true)
      LowLevel.solver_to_dimacs_string(self, include_names)
    end

    def prove!(ast)
      @has_model = false
      push
      assert(~ast)
      case check
      when :sat
        puts "Counterexample exists"
        model.each do |n,v|
          puts "* #{n} = #{v}"
        end
      when :unknown
        puts "Unknown"
      when :unsat
        puts "Proven"
      else
        raise "Wrong SAT result #{r}"
      end
    ensure
      pop
    end

    private

    # Z3 only accepts Bool consts and their negations here, but it raises on the rest
    # itself - all this has to do is turn `true` / `false` into Bool exprs and give a
    # decent error for anything that isn't Bool at all
    def coerce_assumptions(assumptions)
      bool = BoolSort.new
      assumptions.map { |assumption| bool.cast(assumption) }
    end

    def reset_model!
      @has_model = false
      @model = nil
    end

    def check_sat_results(r)
      {
        -1 => :unsat,
        0 => :unknown,
        1 => :sat,
      }[r] or raise Z3::Exception, "Wrong SAT result #{r}"
    end
  end
end
