module Z3
  # Z3's `seq.map`, `seq.mapi`, `seq.fold_left` and `seq.fold_lefti`, which are one
  # set of operations over sequences and strings alike - a String is a Seq(Char) to
  # Z3, so mapping one is the same call with the same meaning. That's why this is a
  # module rather than something on SeqExpr which StringExpr copies: unlike the
  # element-versus-subsequence methods, there's no place where the Ruby readings of
  # the two differ.
  #
  # Each method takes a block or an already built function, never both. The block form
  # conjures a bound variable per argument and is what you want nearly always; the
  # function form is for reusing one across several calls.
  module SeqMapFold
    # Ruby's Array#map. The block gets an element, and the result is a sequence of
    # whatever sort the block returns, so mapping a Seq(Int) through a predicate
    # gives a Seq(Bool).
    def map(function = nil, &block)
      function = unary_function(function, &block)
      SeqSort.new(unary_function_range(function)).new(LowLevel.mk_seq_map(function, self))
    end

    # Ruby's `each_with_index.map`, with the arguments in Z3's order: the block gets
    # the index first, then the element. `from:` is Z3 letting the index start
    # somewhere other than 0, which Ruby has no spelling for.
    #
    # Z3 calls this `seq.mapi`, and #mapi is an alias for anyone reading along with
    # Z3's own documentation. Same for #fold_left and #fold_lefti below. The Ruby
    # names are the primary ones everywhere, printed terms included.
    def map_with_index(function = nil, from: 0, &block)
      function = multi_arg_function([IntSort.new, sort.element_sort], function, &block)
      SeqSort.new(function.range).new(
        LowLevel.mk_seq_mapi(function, IntSort.new.cast(from), self)
      )
    end

    # Ruby's Array#inject / #reduce. The initial value is required, where Ruby's is
    # optional - Ruby's initial-less form starts from the first element, and a
    # symbolic sequence may not have one.
    #
    # The accumulator doesn't have to match the element sort: folding a Seq(Int) from
    # `Z3.Const(true)` with `acc & (x > 0)` asks whether every element is positive.
    def inject(initial, function = nil, &block)
      initial = cast_initial(initial)
      function = multi_arg_function([initial.sort, sort.element_sort], function, &block)
      function.range.new(LowLevel.mk_seq_foldl(function, initial, self))
    end

    alias_method :reduce, :inject

    # #inject with the index, which the block gets before the accumulator and element
    def inject_with_index(initial, function = nil, from: 0, &block)
      initial = cast_initial(initial)
      function = multi_arg_function([IntSort.new, initial.sort, sort.element_sort], function, &block)
      function.range.new(
        LowLevel.mk_seq_foldli(function, IntSort.new.cast(from), initial, self)
      )
    end

    # Z3's own names for the three which have one, so code written against Z3's
    # documentation reads. `seq.map` needs none - Z3 and Ruby already agree.
    alias_method :mapi, :map_with_index
    alias_method :fold_left, :inject
    alias_method :fold_lefti, :inject_with_index

    private

    def cast_initial(initial)
      return initial if initial.is_a?(Expr)
      Expr.sort_for_const(initial).from_const(initial)
    end

    # #map's function is unary, so it's an ordinary one-bound-variable lambda and
    # `Z3.Lambda` builds it - no SeqFunction needed. Two classes can come back from
    # that, though: a function to Bool is an `Array(X, Bool)`, which is a `Set(X)`,
    # so `Z3.Lambda(x, x > 0)` is a SetExpr while `Z3.Lambda(x, x * 2)` is an
    # ArrayExpr. Both are accepted, and the split is by range sort rather than by
    # where the term came from.
    def unary_function(function, &block)
      if block
        raise Z3::Exception, "Pass a function or a block, not both" if function
        var = sort.element_sort.fresh_var("x")
        return Z3.Lambda(var, block.call(var))
      end
      raise Z3::Exception, "#map needs a function or a block" unless function
      unless unary_over_element_sort?(function)
        raise Z3::Exception, "#map wants a one argument function over #{sort.element_sort}, got #{AST.describe(function)}"
      end
      function
    end

    def unary_over_element_sort?(function)
      case function
      when SetExpr then function.sort.element_sort == sort.element_sort
      when ArrayExpr then function.sort.key_sort == sort.element_sort
      else false
      end
    end

    # ...and the same split says what the mapped sequence's element sort is
    def unary_function_range(function)
      function.is_a?(SetExpr) ? BoolSort.new : function.sort.value_sort
    end

    # The other three take a function of two or three arguments, which is a SeqFunction
    # rather than an Expr - see that class for why there's no honest Expr to be had
    def multi_arg_function(arg_sorts, function, &block)
      if block
        raise Z3::Exception, "Pass a function or a block, not both" if function
        return SeqFunction.from_block(*arg_sorts, &block)
      end
      raise Z3::Exception, "Needs a function or a block" unless function
      unless function.is_a?(SeqFunction) and function.arg_sorts == arg_sorts
        # A SeqFunction describes its own sorts, which is exactly what's wrong when
        # one of the right class turns up with the wrong arguments
        got = function.is_a?(SeqFunction) ? function.inspect : AST.describe(function)
        raise Z3::Exception, "Wanted a SeqFunction over (#{arg_sorts.join(", ")}), got #{got}"
      end
      function
    end
  end
end
