if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.command_name "#{File.basename($0)}"
  SimpleCov.start do
    add_filter "/spec/"
  end
  SimpleCov.at_exit do
    # Remove verbosity
    $stderr = open("/dev/null", "w")
  end
end
