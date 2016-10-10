module Z3
  class Solver
    attr_reader :_solver
    def initialize
      @_solver = LowLevel.mk_solver
      LowLevel.solver_inc_ref(self)
      reset_model!
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

    def check
      reset_model!
      result = check_sat_results(LowLevel.solver_check(self))
      @has_model = true if result == :sat
      result
    end

    def satisfiable?
      check == :sat
    end

    def unsatisfiable?
      check == :unsat
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

    def statistics
      _stats = LowLevel::solver_get_statistics(self)
      LowLevel.unpack_statistics(_stats)
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
