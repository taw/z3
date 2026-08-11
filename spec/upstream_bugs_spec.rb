require "rbconfig"

# Bugs in Z3 itself, not in this gem.
#
# Every example here asserts that the bug is *still there*, so a failure in this file
# is good news - it means Z3 fixed something and whatever workaround the example
# stands for can go. Each one says what correct behaviour would look like, so a
# failing example is also most of a bug report.
#
# The gem supports Z3 versions on both sides of a fix, so an example for something 5.0
# fixed asserts the bug below 5.0 and the correct answer at or above it, rather than
# being deleted. Deleting it is for when the oldest Z3 we support has the fix.
#
# Verified against Z3 4.16.0 and 5.0.0.
module Z3
  describe "Z3 upstream bugs" do
    # Two of these take the whole process down, so they have to run somewhere else.
    # Dying on a signal means the bug is still there. Exiting any other way - cleanly,
    # or raising Z3::Exception the way every other bad argument does - means it's fixed.
    def dies_on_a_signal?(ruby_code)
      system(
        RbConfig.ruby, "-I#{__dir__}/../lib", "-rz3", "-e", ruby_code,
        out: File::NULL, err: File::NULL,
      )
      !!$?&.signaled?
    end

    it "the helper can tell a crash from an ordinary failure" do
      expect(dies_on_a_signal?("Process.kill :SEGV, $$")).to be true
      expect(dies_on_a_signal?("Z3::Solver.new.check")).to be false
      expect(dies_on_a_signal?("raise Z3::Exception, 'nope'")).to be false
    end

    # Asserting `r == a.to_real` alongside `a == 0.5` returns :sat with a model saying
    # `r = 2`, and that same model then evaluates the constraint it supposedly
    # satisfies to false. `spec/float_expr_spec.rb` works around this by simplifying
    # `#to_real` instead of solving with it - the term the gem builds is correct, it's
    # only the solver that goes wrong once a Real constraint is involved. That
    # workaround is version-independent, so it stays until 4.16 support goes.
    #
    # Correct, and what 5.0 does: a model in which `r` is 1/2.
    it "fp.to_real gives a model which contradicts its own constraint" do
      a = FloatSort.new(11, 53).var("a")
      r = Z3.Real("r")
      constraint = (r == a.to_real)

      solver = Solver.new
      solver.assert a == 0.5
      solver.assert constraint
      expect(solver.check).to eq(:sat)
      expect(solver.model.model_eval(a == 0.5, true).to_b).to be true

      if Z3.version_at_least?(5, 0)
        expect(solver.model.model_eval(constraint, true).to_b).to be true
        expect(solver.model[r].to_r).to eq(Rational(1, 2))
      else
        # Not asserting which wrong value it picks, only that it is wrong - a different
        # wrong answer is the same bug, and shouldn't read as a fix
        expect(solver.model.model_eval(constraint, true).to_b).to be false
      end
    end

    # The `elim-unconstrained` simplifier drops a variable it considers unconstrained
    # and never reconstructs it, so the model it returns doesn't satisfy the
    # assertions. Of the 26 simplifiers 4.16 has this is the only unsound one - the
    # other 25 all round-trip this problem correctly. The `z3` binary on the same
    # problem answers x=4.
    #
    # `Simplifier.unsound` refuses to build this one below 5.0, so the reproduction has
    # to go through LowLevel to get past that guard - which it keeps doing on 5.0 too,
    # so that both branches exercise the same solver.
    #
    # Correct, and what 5.0 does: a model in which `x` is `y + 3`.
    it "the elim-unconstrained simplifier returns a model which fails its assertions" do
      # Z3 collects a simplifier which nothing holds a reference to, and then dies
      # inside the solver, so this has to claim it the way ReferenceCounted would
      _simplifier = LowLevel.mk_simplifier("elim-unconstrained")
      LowLevel.inc_ref_pointer(:simplifier, _simplifier)
      holder = Struct.new(:_simplifier).new(_simplifier)

      # A simplifier can only be attached to a solver with nothing asserted yet, and
      # `solver_add_simplifier` hands back a different solver rather than changing this one
      solver = Solver.new({}, LowLevel.solver_add_simplifier(Solver.new, holder))

      x, y = Z3.Int("x"), Z3.Int("y")
      definition = (x == y + 3)
      solver.assert definition
      solver.assert y > 0

      expect(solver.check).to eq(:sat)
      expect(solver.model.model_eval(y > 0, true).to_b).to be true
      expect(solver.model.model_eval(definition, true).to_b).to be Z3.version_at_least?(5, 0)
    end

    # `Z3_mk_enumeration_sort`'s last two arguments are out arrays, and passing NULL
    # for either segfaults instead of skipping that output. Everything they contain is
    # recoverable from the sort afterwards, so a caller who doesn't want them has no
    # reason to expect they're mandatory. `LowLevel.mk_enumeration_sort` always
    # allocates both because of this.
    #
    # Correct: either fill in nothing, or raise Z3_INVALID_ARG.
    it "Z3_mk_enumeration_sort segfaults on a NULL out array" do
      expect(dies_on_a_signal?(<<~RUBY)).to be true
        _names = FFI::MemoryPointer.new(:pointer, 1)
        _names.write_array_of_pointer([Z3::LowLevel.mk_string_symbol("a")])
        Z3::VeryLowLevel.Z3_mk_enumeration_sort(
          Z3::LowLevel._ctx_pointer,
          Z3::LowLevel.mk_string_symbol("NullOuts"),
          1, _names, nil, nil,
        )
      RUBY
    end

    # `#maximize` hands back an objective index, `pop` throws the objective away, and
    # the index you're still holding then segfaults rather than being rejected. Z3
    # bounds-checks this everywhere else: an index which was never valid raises
    # Z3_EXCEPTION "index out of bounds", and so does reading a bound before #check.
    # It's only an index which *used* to be valid that crashes.
    #
    # Correct: Z3_EXCEPTION "index out of bounds", like every other bad index.
    it "Z3_optimize_get_upper segfaults for an objective a pop has removed" do
      expect(dies_on_a_signal?(<<~RUBY)).to be true
        a = Z3.Int("a")
        optimize = Z3::Optimize.new
        optimize.assert a > 0
        optimize.assert a < 9
        optimize.push
        i = optimize.maximize a
        optimize.check
        optimize.pop
        Z3::LowLevel.optimize_get_upper(optimize, i)
      RUBY
    end

    # Two enum values with the same name are accepted, and Z3 then hash-conses them
    # into one constructor while still reporting the count it was given. So the sort
    # says it has two constructors, both indices give back the identical func decl,
    # and the solver - correctly - treats it as a sort with a single value.
    #
    # Not a soundness bug, just a count that lies. `EnumSort` rejects duplicates
    # itself rather than passing them through.
    #
    # Correct: reject the duplicate, or report the number of distinct constructors.
    it "Z3_mk_enumeration_sort miscounts constructors when two values share a name" do
      _ctx = LowLevel._ctx_pointer
      _names = FFI::MemoryPointer.new(:pointer, 2)
      _names.write_array_of_pointer([LowLevel.mk_string_symbol("a"), LowLevel.mk_string_symbol("a")])
      _consts = FFI::MemoryPointer.new(:pointer, 2)
      _testers = FFI::MemoryPointer.new(:pointer, 2)
      _sort = VeryLowLevel.Z3_mk_enumeration_sort(
        _ctx, LowLevel.mk_string_symbol("DuplicateValueNames"), 2, _names, _consts, _testers,
      )

      expect(VeryLowLevel.Z3_get_datatype_sort_num_constructors(_ctx, _sort)).to eq(2)
      expect(VeryLowLevel.Z3_get_datatype_sort_constructor(_ctx, _sort, 0))
        .to eq(VeryLowLevel.Z3_get_datatype_sort_constructor(_ctx, _sort, 1))

      # The solver knows better than the count does
      x = Expr.new_from_pointer(VeryLowLevel.Z3_mk_const(_ctx, LowLevel.mk_string_symbol("dup_x"), _sort))
      y = Expr.new_from_pointer(VeryLowLevel.Z3_mk_const(_ctx, LowLevel.mk_string_symbol("dup_y"), _sort))
      solver = Solver.new
      solver.assert x != y
      expect(solver.check).to eq(:unsat)
    end
  end
end
