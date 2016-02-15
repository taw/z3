module Z3
end

class Z3::Exception < StandardError
end

# module Z3::TrueCoertionMixin
#   def ==(other)
#     p [:true_eqeq, self, other]
#     Z3::Ast.true == other if other.is_a?(Z3::Ast)
#     super
#   end
# end

# module Z3::FalseCoertionMixin
#   def ==(other)
#     p [:false_eqeq, self, other]
#     Z3::Ast.false == other if other.is_a?(Z3::Ast)
#     super
#   end
# end

# class TrueClass
#   include Z3::TrueCoertionMixin
# end

# class FalseClass
#   include Z3::FalseCoertionMixin
# end

require_relative "z3/core"
require_relative "z3/context"
require_relative "z3/solver"
require_relative "z3/sort"
require_relative "z3/ast"
