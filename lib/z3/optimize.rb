module Z3
  class Optimize
    include ReferenceCounted

    attr_reader :_optimize

    def initialize(params = {})
      @_optimize = LowLevel.mk_optimize
      inc_ref! :optimize, @_optimize
      reset_model!
      # Skipped for the common no-parameters case, as #set_params has to build
      # the parameter descriptions to check against
      set_params(params) unless params == {}
    end

    # Optimize takes far fewer parameters than Solver does
    def param_descrs
      ParamDescrs.new(LowLevel.optimize_get_param_descrs(self))
    end

    # Parameters accumulate - setting one twice overrides it, but parameters set
    # by earlier calls stay. Pass a Params if you want to skip the name and type
    # checks, a Hash if you don't.
    def set_params(params)
      params = Params.new(params, param_descrs) unless params.is_a?(Params)
      LowLevel.optimize_set_params(self, params)
      self
    end

    def push
      reset_model!
      LowLevel.optimize_push(self)
    end

    def pop
      reset_model!
      LowLevel.optimize_pop(self)
    end

    def assert(ast)
      reset_model!
      LowLevel.optimize_assert(self, ast)
    end

    # `tracker` is a Bool const standing in for `ast`, and it's what shows up in
    # #unsat_core if the solver blames this assertion
    def assert_and_track(ast, tracker)
      reset_model!
      LowLevel.optimize_assert_and_track(self, ast, tracker)
    end

    def assert_soft(ast, weight = "1", id = nil)
      reset_model!
      LowLevel.optimize_assert_soft(self, ast, weight, id)
    end

    def check(*args)
      reset_model!
      result = check_sat_results(LowLevel.optimize_check(self, args))
      @has_model = true if result == :sat
      result
    end

    def satisfiable?
      case check
      when :sat
        true
      when :unsat
        false
      else
        raise Z3::Exception, "Satisfiability unknown"
      end
    end

    def unsatisfiable?
      case check
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
        @model ||= Z3::Model.new(LowLevel.optimize_get_model(self))
      else
        raise Z3::Exception, "You need to check that it's satisfiable before asking for the model"
      end
    end

    def assertions
      _ast_vector = LowLevel.optimize_get_assertions(self)
      LowLevel.unpack_ast_vector(_ast_vector)
    end

    # Only the trackers passed to #assert_and_track can ever show up here,
    # plainly asserted formulas are never blamed
    def unsat_core
      _ast_vector = LowLevel.optimize_get_unsat_core(self)
      LowLevel.unpack_ast_vector(_ast_vector)
    end

    def statistics
      _stats = LowLevel::optimize_get_statistics(self)
      LowLevel.unpack_statistics(_stats)
    end

    def help
      LowLevel.optimize_get_help(self)
    end

    def to_s
      LowLevel.optimize_to_string(self)
    end

    def prove!(ast)
      @has_model = false
      push
      assert(~ast)
      case check
      when :sat
        puts "Counterexample exists"
        model.each do |n, v|
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

    def reason_unknown
      LowLevel.optimize_get_reason_unknown(self)
    end

    def maximize(ast)
      reset_model!
      LowLevel.optimize_maximize(self, ast)
    end

    def minimize(ast)
      reset_model!
      LowLevel.optimize_minimize(self, ast)
    end

    # A hint at which value to try for a variable first - a warm start, for feeding a
    # known-good solution back in. It stays a hint: an impossible one is overridden
    # rather than believed, and it can't make an unsat problem sat.
    #
    # Bool and Bitvec only, unlike Solver#set_initial_value, because Z3's optimizer gets
    # arithmetic ones wrong in both directions: an Int hint is dropped by its `elim_01`
    # preprocessing before the search ever sees it, and a Real hint which does arrive
    # comes back out of that preprocessing scaled, so an Optimize with an objective can
    # answer with a model that fails its own assertions. `spec/upstream_bugs_spec.rb`
    # reproduces both, through LowLevel to get past this guard. Solver.simple honours Int
    # and Real warm starts correctly, and is where an arithmetic one belongs until Z3 is
    # fixed.
    #
    # Z3 acts on the hint for Bool (the initial phase) and Bitvec (a phase per bit).
    # Other sorts - String, Seq and Float among them - it accepts and ignores, and
    # there's no way to be told which is which.
    def set_initial_value(var, value)
      unless var.is_a?(Expr) and var.ast_kind == :app and var.func_decl.arity == 0
        raise Z3::Exception, "Initial values are for variables, and #{var.inspect} is not one"
      end
      if var.sort.is_a?(IntSort) or var.sort.is_a?(RealSort)
        raise Z3::Exception,
          "Optimize drops Int initial values and answers unsoundly for Real ones, " \
          "use Solver.simple for an arithmetic warm start"
      end
      LowLevel.optimize_set_initial_value(self, var, var.sort.cast(value))
      self
    end

    # Parses SMT-LIB2 and adds its assertions on top of whatever's already asserted.
    # Anything it declares goes into the shared context, so `(declare-const a Int)`
    # here is the same variable as `Z3.Int("a")` in Ruby - but the parser starts with
    # an empty symbol table every time, so each string has to declare what it uses.
    #
    # `(maximize ...)`, `(minimize ...)` and `(assert-soft ...)` are understood too,
    # so a string can bring objectives along with its assertions.
    def from_string(str)
      reset_model!
      LowLevel.optimize_from_string(self, str)
      self
    end

    def from_file(path)
      reset_model!
      LowLevel.optimize_from_file(self, path)
      self
    end

    private

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
