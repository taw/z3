require "pathname"

Gem::Specification.new do |s|
  s.name         = "z3"
  s.version      = "0.0.20180203"
  s.date         = "2018-02-03"
  s.summary      = "Z3 Constraint Solver"
  s.description  = "Ruby bindings for Z3 Constraint Solver"
  s.authors      = ["Tomasz Wegrzanowski"]
  s.email        = "Tomasz.Wegrzanowski@gmail.com"
  s.files        = %W[Rakefile .rspec examples lib spec README.md].map{|x| Pathname(x).find.to_a.select(&:file?)}.flatten.map(&:to_s)
  s.homepage     = "https://github.com/taw/z3"
  s.license      = "MIT"
  s.requirements = "z3 library"
  # development
  s.add_development_dependency "pry"
  # tests
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "regexp_parser"
  s.add_runtime_dependency "ffi"
end
