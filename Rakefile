require "json"

task "default" => "spec"
task "test" => "spec"
task "test:integration" => "spec:integration"
task "test:unit" => "spec:unit"

desc "Regenerate API"
task "api" do
  sh "./api/gen_api api/definitions.h"
end

desc "Clean up"
task "clean" do
  sh "trash z3-*.gem coverage"
end

desc "Run tests"
task "spec" do
  sh "rspec"
end

desc "Run unit tests"
task "spec:unit" do
  sh "rspec spec/*_spec.rb"
end

desc "Run integration tests"
task "spec:integration" do
  sh "rspec spec/integration/*_spec.rb"
end

desc "Build gem"
task "gem:build" do
  sh "gem build z3.gemspec"
end

desc "Upload gem"
task "gem:push" => "gem:build" do
  gem_file = Dir["z3-*.gem"][-1] or raise "No gem found"
  sh "gem", "push", gem_file
end

desc "Report missing APIs"
task "coverage:missing" do
  sh "COVERAGE=1 rake test"
  data = JSON.load(open("coverage/.resultset.json"))["RSpec"]["coverage"]
  lla_path = data.keys.find{|k| k.end_with?("lib/z3/low_level_auto.rb")}
  coverage = data[lla_path].zip(File.readlines(lla_path).map(&:strip))
  missing = coverage.each_cons(2).map(&:flatten).select{|_,_,bc,_| bc == 0}.map{|_,a,_,_| a.sub(/\Adef /, "")}
  # Also missing is everything that uses too fancy calling convention for automated generation
  # That's currently 60 functions
  open("missing_apis.txt", "w") do |file|
    file.puts missing
  end
end