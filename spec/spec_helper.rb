require "pry"

if ENV["COVERAGE"]
  require 'simplecov'
  SimpleCov.start
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
    actual = IO.popen(executable_path).read
    actual.gsub(/ *$/, "") == expected.gsub(/ *$/, "")
  end
end

RSpec::Matchers.define :be_same_as do |expected|
  match do |file_name|
    [actual.class, actual.inspect] == [expected.class, expected.inspect]
  end
end
