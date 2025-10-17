require "pathname"

Gem::Specification.new do |s|
  s.name = "z3"
  s.version = "0.0.20251017"
  s.date = "2025-10-17"
  s.summary = "Z3 Constraint Solver"
  s.description = "Ruby bindings for Z3 Constraint Solver"
  s.authors = ["Tomasz Wegrzanowski"]
  s.email = "Tomasz.Wegrzanowski@gmail.com"
  s.files = %W[Rakefile .rspec examples lib spec README.md].map { |x| Pathname(x).find.to_a.select(&:file?) }.flatten.map(&:to_s)
  s.homepage = "https://github.com/taw/z3"
  s.license = "MIT"
  s.requirements = "z3 library (4.8+)"
  # development
  s.add_development_dependency "pry"
  s.metadata['msys2_mingw_dependencies'] = 'z3'
  # tests
  s.add_development_dependency "rake", ">= 13"
  s.add_development_dependency "rspec", "~> 3.13"
  s.add_development_dependency "simplecov", "~> 0.22"
  s.add_development_dependency "regexp_parser", "~> 1.8"
  s.add_development_dependency "paint", ">= 2.3.0"
  s.add_runtime_dependency "ffi", "~> 1.17"
end
