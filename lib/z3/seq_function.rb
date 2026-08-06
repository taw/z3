module Z3
  # A lambda over more than one bound variable, which is what `seq.mapi`,
  # `seq.fold_left` and `seq.fold_lefti` all take. Z3 makes such a lambda an n-ary
  # Array - `Array(Int, Int, Int)` for a binary one - and this gem has no
  # representation for those. `Sort.from_pointer` reports it as `Array(Int, Int)`,
  # which is a lie, and every Array operation on it then fails inside Z3 rather than
  # in Ruby.
  #
  # So this deliberately isn't an Expr. It's an opaque handle over the raw AST, with
  # the argument sorts and range recorded on the Ruby side where they're true, and its
  # only purpose is to be handed back to one of those three operations. It answers to
  # `#_ast`, which is all LowLevel wants of it, and to nothing else.
  #
  # Multi-dimensional array sorts would retire the whole class, letting `Z3.Lambda`
  # take a list of bound variables and give back an honest Expr.
  class SeqFunction
    attr_reader :_ast, :arg_sorts, :range

    # One bound variable per argument sort, handed to the block, whose result is the
    # body. A Ruby literal body is cast the same way `Z3.Lambda` casts one.
    def self.from_block(*arg_sorts, &block)
      raise Z3::Exception, "A function needs a block" unless block
      arg_sorts.each do |sort|
        raise Z3::Exception, "Argument sorts expected, got #{sort.class}" unless sort.is_a?(Sort)
      end
      unless block.arity < 0 or block.arity == arg_sorts.size
        raise Z3::Exception, "Block takes #{block.arity} argument#{"s" unless block.arity == 1}, expected #{arg_sorts.size}"
      end
      # Fresh, so a block which closes over a variable of the same name can't capture
      # the bound one by accident
      vars = arg_sorts.each_with_index.map { |sort, i| sort.fresh_var("arg#{i}") }
      body = block.call(*vars)
      body = Expr.sort_for_const(body).from_const(body) unless body.is_a?(Expr)
      new(LowLevel.mk_lambda_const(vars, body), arg_sorts, body.sort)
    end

    def initialize(_ast, arg_sorts, range)
      @_ast, @arg_sorts, @range = _ast, arg_sorts, range
    end

    def to_s
      "Z3::SeqFunction<(#{arg_sorts.join(", ")}) -> #{range}>"
    end

    alias_method :inspect, :to_s
  end
end
