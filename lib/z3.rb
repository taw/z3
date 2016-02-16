module Z3
  def self.version
    Z3::LowLevel.get_version.join(".")
  end
end

class Z3::Exception < StandardError
end

require_relative "z3/very_low_level"
require_relative "z3/low_level"
require_relative "z3/context"
require_relative "z3/solver"
require_relative "z3/sort"
require_relative "z3/ast"
require_relative "z3/model"
require_relative "z3/func_decl"
