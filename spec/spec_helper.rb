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
  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end
end

RSpec::Matchers.define :have_output do |expected|
  match do |file_name|
    executable_path = "#{__dir__}/../examples/#{file_name}"
    actual = IO.popen("ruby -r./spec/coverage_helper #{executable_path}").read
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

RSpec::Matchers.define :have_solution do |expected|
  match do |asts|
    solver = setup_solver(asts)
    solver.satisfiable? and expected.all?{|var,val| solver.model[var].to_s == val.to_s}
  end

  failure_message do |asts|
    solver = setup_solver(asts)
    if solver.satisfiable?
      "expected #{asts.inspect} to have solution #{expected.inspect}, instead got #{solver.model}"
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
    solutions = get_all_solutions(asts)
    solutions == expected
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
