Gem::Specification.new do |s|
  s.name         = "z3"
  s.version      = "0.0.20160427"
  s.date         = "2016-04-27"
  s.summary      = "Z3 Constraint Solver"
  s.description  = "Ruby bindings for Z3 Constraint Solver"
  s.authors      = ["Tomasz Wegrzanowski"]
  s.email        = 'Tomasz.Wegrzanowski@gmail.com'
  s.files        = FileList["examples/*", "lib/**/*", "spec/**/*", "README.md"]
  s.homepage     = "https://github.com/taw/z3"
  s.license      = "MIT"
  s.requirements = "z3 library"
  # development
  s.add_development_dependency 'pry'
  # tests
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'simplecov'
  s.add_runtime_dependency 'ffi'
end
