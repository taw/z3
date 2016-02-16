class Z3::Solver
  attr_reader :_solver
  def initialize
    @_solver = Z3::LowLevel.mk_solver
    Z3::LowLevel.solver_inc_ref(self)
  end

  def push
    Z3::LowLevel.solver_push(self)
  end

  def pop(n=1)
    Z3::LowLevel.solver_pop(self, n)
  end

  def reset
    Z3::LowLevel.solver_reset(self)
  end

  def assert(ast)
    Z3::LowLevel.solver_assert(self, ast)
  end

  def check
    check_sat_results(Z3::LowLevel.solver_check(self))
  end

  def model
    Z3::Model.new(
      Z3::LowLevel.solver_get_model(self)
    )
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
    case r
    when 1
      :sat
    when 0
      :unknown
    when -1
      :unsat
    else
      raise "Wrong SAT result #{r}"
    end
  end
end
