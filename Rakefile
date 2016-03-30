desc "Regenerate API"
task :api do
  system "./api/gen_api api/definitions.h"
end

desc "Clean up"
task :clean do
  system "trash z3-*.gem coverage"
end

task "gem:build" do
  system "gem build z3.gemspec"
end

task "gem:push" => "gem:build" do
  gem_file = Dir["z3-*.gem"][-1] or raise "No gem found"
  system "gem", "push", gem_file
end
