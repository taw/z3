require "pry"

if ENV["COVERAGE"]
  require 'simplecov'
  SimpleCov.start do
    add_filter "/spec/"
  end
end

require_relative "../lib/z3"

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.define_derived_metadata do |meta|
    meta[:aggregate_failures] = true
  end
end

RSpec::Matchers.define :have_output do |expected|
  match do |file_name|
    executable_path = "#{__dir__}/../examples/#{file_name}"
    actual = IO.popen("ruby -r./spec/coverage_helper #{executable_path}").read
    @expected = expected.gsub(/ *$/, "")
    @actual = actual.gsub(/ *$/, "")
    @actual == @expected
  end

  failure_message do |actual|
    "Expected:\n#{@expected.chomp}\nBut got:\n#{@actual}"
  end
end

RSpec::Matchers.define :have_output_matching_saved_example do
  match do |file_name|
    executable_path = "#{__dir__}/../examples/#{file_name}"
    actual = IO.popen("ruby -r./spec/coverage_helper #{executable_path}").read
    @actual = actual.gsub(/ *$/, "")
    @expected = Pathname("spec/integration/examples").glob("#{file_name}-*.txt").map(&:read).map{|o| o.gsub(/ *$/, "")}
    @expected.include?(@actual)
  end

  failure_message do |actual|
    "Expected one of saved examples, but got:\n#{@actual}"
  end
end

RSpec::Matchers.define :have_output_no_color do |expected|
  match do |file_name|
    executable_path = "#{__dir__}/../examples/#{file_name}"
    actual = IO.popen("ruby -r./spec/coverage_helper #{executable_path}").read
    actual = actual.gsub(/\e\[.*?m/, "")
    actual.gsub(/ *$/, "") == expected.gsub(/ *$/, "")
  end
end

RSpec::Matchers.define :be_same_as do |expected|
  match do |file_name|
    [actual.class, actual.inspect] == [expected.class, expected.inspect]
  end
end

RSpec::Matchers.define :be_all_same do
  match do |array|
    array.uniq.size == 1
  end
end

RSpec::Matchers.define :be_all_different do
  match do |array|
    array.uniq.size == array.size
  end
end

RSpec::Matchers.define :stringify do |expected|
  match do |actual|
    actual.to_s == expected
  end

  failure_message do
    "Expected #{actual.inspect} to stringify to `#{expected}', got `#{actual.to_s}' instead"
  end
end

# Expectations are checked by asking the model whether `var == val` holds, not by
# comparing printed forms. Stringifying both sides went through the printer, which
# drops the sort - an Int `1` and a Real `1` print the same, so do bitvectors of
# different widths - and it forced expectations to be written in printer syntax.
# `model_eval` with completion answers the question actually being asked: does this
# model give the variable this value.
RSpec::Matchers.define :have_solution do |expected|
  match do |asts|
    solver = setup_solver(asts)
    solver.satisfiable? and expected.all?{|var,val| model_says_equal?(solver.model, var, val)}
  end

  # Model evaluation normally comes back as a literal true or false. Arrays and sets
  # are the exception - Z3's evaluator won't decide extensional equality, so it hands
  # back the equality term unreduced, and the simplifier won't either, so #value
  # refuses it. Everything in the term is ground by then, so a solver settles it:
  # equal exactly when the negation can't be satisfied.
  def model_says_equal?(model, var, val)
    result = model.model_eval(var == val, true)
    begin
      result.value == true
    rescue Z3::Exception
      !setup_solver([~result]).satisfiable?
    end
  end

  failure_message do |asts|
    solver = setup_solver(asts)
    if solver.satisfiable?
      "expected #{asts.inspect} to have solution:\n#{
        expected.map{|var,val| "#{var}=#{val}\n"}.join
      }instead got:\n#{
        solver.model.map{|var,val| "#{var}=#{solver.model[var]}\n"}.join
      }"
    else
      "expected #{asts.inspect} to have solution #{expected.inspect}, instead not solvable"
    end
  end

  def setup_solver(asts)
    Z3::Solver.new.tap do |solver|
      asts.each do |ast|
        solver.assert ast
      end
    end
  end
end

RSpec::Matchers.define :have_solutions do |expected|
  match do |asts|
    same_solutions?(get_all_solutions(asts), expected)
  end

  # Comparing the two Arrays of Hashes with == checked far less than it looked like.
  # Hash#== compares values with ==, and == on two Exprs builds an expression instead
  # of answering - a truthy one, so any pair of values passed. Only the keys were ever
  # really checked, as Hash looks those up through hash and eql?. Both sides hold
  # concrete model values here, so eql? is what decides them.
  #
  # Order isn't part of the claim either - the solver hands its solutions back in
  # whatever order it found them, which is its own business and moves between Z3
  # versions - so each expected solution has to pair off against one that turned up.
  def same_solutions?(got, expected)
    unmatched = got.dup
    expected.each do |wanted|
      found = unmatched.index{|solution| same_solution?(solution, wanted)}
      return false unless found
      unmatched.delete_at(found)
    end
    unmatched.empty?
  end

  def same_solution?(got, expected)
    got.size == expected.size and got.all? do |var, value|
      expected.key?(var) and value.eql?(expected[var])
    end
  end

  failure_message do |asts|
    solutions = get_all_solutions(asts)
    "expected #{asts.inspect} to have solutions:\n#{expected.map{|s| "* #{s.inspect}\n"}.join}, instead got:\n#{solutions.map{|s| "* #{s.inspect}\n"}.join}"
  end

  def get_all_solutions(asts)
    vars = expected.map(&:keys)
    raise "All expectations need same set of keys" unless vars.uniq.size == 1
    vars = vars[0]
    solver = setup_solver(asts)
    solutions = []
    while solver.satisfiable?
      model = solver.model
      solution = Hash[vars.map{|v| [v, model.model_eval(v, true)] }]
      solutions << solution
      solver.assert Z3.Or(*solution.map{|var,val| var != val})
      if solutions.size >= 10
        binding.pry
        raise "Too many solutions found, presumably infinite loop"
      end
    end
    solutions
  end

  def setup_solver(asts)
    Z3::Solver.new.tap do |solver|
      asts.each do |ast|
        solver.assert ast
      end
    end
  end
end

RSpec::Matchers.define :have_no_solution do
  match do |asts|
    solver = setup_solver(asts)
    !solver.satisfiable?
  end

  failure_message do |asts|
    "expected #{asts.inspect} to have no solutions, but solution found"
  end

  def setup_solver(asts)
    Z3::Solver.new.tap do |solver|
      asts.each do |ast|
        solver.assert ast
      end
    end
  end
end
