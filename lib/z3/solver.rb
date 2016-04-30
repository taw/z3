module Z3
  class Solver
    attr_reader :_solver
    def initialize
      @_solver = LowLevel.mk_solver
      LowLevel.solver_inc_ref(self)
    end

    def push
      LowLevel.solver_push(self)
    end

    def pop(n=1)
      LowLevel.solver_pop(self, n)
    end

    def reset
      LowLevel.solver_reset(self)
    end

    def assert(ast)
      LowLevel.solver_assert(self, ast)
    end

    def check
      check_sat_results(LowLevel.solver_check(self))
    end

    def model
      Z3::Model.new(
        LowLevel.solver_get_model(self)
      )
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

    def check_sat_results(r)
      {
        -1 => :unsat,
        0 => :unknown,
        1 => :sat,
      }[r] or raise Z3::Exception, "Wrong SAT result #{r}"
    end
  end
end
