desc "Regenerate API"
task :api do
  system "./api/gen_api api/definitions.h"
end

desc "Clean up"
task :clean do
  system "trash z3-*.gem coverage"
end
