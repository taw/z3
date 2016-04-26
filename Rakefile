task "default" => "spec"
task "test" => "spec"
task "test:integration" => "spec:integration"
task "test:unit" => "spec:unit"

desc "Regenerate API"
task "api" do
  system "./api/gen_api api/definitions.h"
end

desc "Clean up"
task "clean" do
  system "trash z3-*.gem coverage"
end

desc "Run tests"
task "spec" do
  system "rspec"
end

desc "Run unit tests"
task "spec:unit" do
  system "rspec spec/*_spec.rb"
end

desc "Run integration tests"
task "spec:integration" do
  system "rspec spec/integration/*_spec.rb"
end

desc "Build gem"
task "gem:build" do
  system "gem build z3.gemspec"
end

desc "Upload gem"
task "gem:push" => "gem:build" do
  gem_file = Dir["z3-*.gem"][-1] or raise "No gem found"
  system "gem", "push", gem_file
end
