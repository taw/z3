module Z3
  class Optimize
    attr_reader :_optimize
    def initialize
      @_optimize = LowLevel.mk_optimize
      LowLevel.optimize_inc_ref(self)
      reset_model!
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

    def assert_soft(ast)
      reset_model!
      LowLevel.optimize_assert_soft(self, ast)
    end

    def check
      reset_model!
      result = check_sat_results(LowLevel.optimize_check(self))
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

    def statistics
      _stats = LowLevel::optimize_get_statistics(self)
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


    def reason_unknown
      LowLevel.optimize_get_reason_unknown(self)
    end

    def maximize(ast)
      LowLevel.optimize_maximize(self, ast)
    end

    def minimize(ast)
      LowLevel.optimize_minimize(self, ast)
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
