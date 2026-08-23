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
# Verified against Z3 4.16.0, 5.0.0 and 5.1.0.
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

    # One of these doesn't come back at all, so it has to run somewhere else too - and
    # somewhere else that can be killed, since the whole point is that nothing inside
    # Z3 will stop it. `timeout` and `rlimit` are no help: Z3 never looks at either
    # from inside the loop, which is why this is a hang rather than an `:unknown`.
    #
    # `seconds` is generous because a slow machine finishing in 4s and a hang look the
    # same from out here, and a false "still broken" is the worse of the two mistakes.
    def hangs?(ruby_code, seconds: 10)
      pid = spawn(
        RbConfig.ruby, "-I#{__dir__}/../lib", "-rz3", "-e", ruby_code,
        out: File::NULL, err: File::NULL,
      )
      finished = nil
      waiter = Thread.new { finished = Process.wait2(pid)&.last }
      hung = waiter.join(seconds).nil?
      if hung
        Process.kill(:KILL, pid)
        waiter.join
      end
      hung
    end

    it "the hang helper can tell a hang from an ordinary answer" do
      expect(hangs?("sleep 60", seconds: 2)).to be true
      expect(hangs?("Z3::Solver.new.check", seconds: 30)).to be false
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

    # Z3 5.0 added finite sets without adding a `Z3_FINITE_SET_SORT` to `Z3_sort_kind`,
    # so `Z3_get_sort_kind` answers `Z3_UNKNOWN_SORT` for one. It's the only sort family
    # in Z3 with no kind of its own, and `Z3_is_finite_set_sort` is the only way to
    # recognise one. Appending to the enum would break nothing: slot 15 is unused, and
    # `Z3_UNKNOWN_SORT` is pinned at 1000 for exactly that reason.
    #
    # Upstream knows. Z3's own Python bindings work around it identically, testing
    # `Z3_is_finite_set_sort` ahead of the kind dispatch in both `_to_sort_ref` and
    # `_to_expr_ref`, the second carrying the comment "Check for finite set sort before
    # checking sort kind". The C++ API has all 14 finite set constructors and no
    # `sort::is_finite_set()` at all.
    #
    # This is not the `Z3_is_string_sort` / `Z3_is_seq_sort` situation, where the
    # predicate narrows within a kind that does exist - a String really is a
    # `Z3_SEQ_SORT`.
    #
    # Correct: `Z3_FINITE_SET_SORT`, and `Sort.from_pointer` dispatching on it like
    # every other sort.
    it "Z3_get_sort_kind has no kind for a finite set sort" do
      skip "Finite sets were added in Z3 5.0" unless Z3.version_at_least?(5, 0)
      _finite_set = LowLevel.mk_finite_set_sort(IntSort.new)

      # 1000 is Z3_UNKNOWN_SORT, the fallback for a sort the API can't classify
      expect(VeryLowLevel.Z3_get_sort_kind(LowLevel._ctx_pointer, _finite_set)).to eq(1000)

      # `Sort.from_pointer` gets there anyway, by asking the predicate first. Without
      # that it would fall through its kind dispatch to "Unknown sort kind 1000", and
      # take every model holding a finite set with it.
      expect(Sort.from_pointer(_finite_set)).to eq(FiniteSetSort.new(IntSort.new))
    end

    # The workaround for the above, which is what `Sort.from_pointer` will have to do
    # once there's a FiniteSetSort to dispatch to. Testing a predicate before the kind
    # dispatch is only safe if it never fires on a sort the dispatch already handles,
    # so that's what this pins: every sort the gem has, answering false, and the finite
    # set answering true.
    #
    # If Z3 ever does add the kind, this example goes on passing - it's the one above
    # that fails, which is the right way round.
    it "Z3_is_finite_set_sort works as a substitute for the missing sort kind" do
      skip "Finite sets were added in Z3 5.0" unless Z3.version_at_least?(5, 0)
      _finite_set = LowLevel.mk_finite_set_sort(IntSort.new)
      expect(VeryLowLevel.Z3_is_finite_set_sort(LowLevel._ctx_pointer, _finite_set)).to be true

      # Every sort `Sort.from_pointer` knows how to build, including both datatype
      # shapes - names are unique to this example, as enums and tuples can only be
      # declared once per context
      every_other_sort = [
        BoolSort.new,
        IntSort.new,
        RealSort.new,
        BitvecSort.new(8),
        FloatSort.new(11, 53),
        RoundingModeSort.new,
        CharSort.new,
        StringSort.new,
        SeqSort.new(IntSort.new),
        ReSort.new(SeqSort.new(IntSort.new)),
        ArraySort.new(IntSort.new, IntSort.new),
        SetSort.new(IntSort.new),
        UninterpretedSort.new("FiniteSetProbeUninterpreted"),
        FiniteDomainSort.new("FiniteSetProbeFiniteDomain", 5),
        EnumSort.new("FiniteSetProbeEnum", %i[a b]),
        TupleSort.new("FiniteSetProbeTuple", x: IntSort.new),
        TypeVariableSort.new("FiniteSetProbeTypeVar"),
      ]
      expect(every_other_sort.map { |sort| LowLevel.is_finite_set_sort(sort) }).to all(be false)

      # And the elements of a finite set are readable, so a FiniteSetSort can be
      # rebuilt from a bare pointer the way every other named sort is
      _basis = VeryLowLevel.Z3_get_finite_set_sort_basis(LowLevel._ctx_pointer, _finite_set)
      expect(Sort.from_pointer(_basis)).to eq(IntSort.new)
    end

    # Z3 5.0's model evaluator has no rules for finite sets at all. Asked what
    # `set.size s` or `set.in 7 s` comes to in a model which says `s` is the entirely
    # concrete `(set.singleton 7)`, it hands the term straight back unreduced - with
    # model completion on, which is meant to guarantee a literal.
    #
    # This is not the `set.unique` abstraction Z3 uses for sets it never had to pin
    # down. There is nothing left to decide in `(set.size (set.singleton 7))`, and the
    # simplifier decides it - see the next example.
    #
    # It matters beyond `#value`, because `Model#model_eval` is how `Model#[]`, the
    # `have_solution` matcher and `Solver#prove!` all ask a model what it says. Any
    # finite set reader will have to go through the simplifier instead.
    #
    # Correct: `1` and `true`, the way every other sort's operations evaluate.
    it "Z3_model_eval can't evaluate finite set operations, even on a concrete set" do
      skip "Finite sets were added in Z3 5.0" unless Z3.version_at_least?(5, 0)
      _ctx = LowLevel._ctx_pointer
      _int = IntSort.new._ast
      _seven = VeryLowLevel.Z3_mk_numeral(_ctx, "7", _int)
      _set = VeryLowLevel.Z3_mk_const(
        _ctx, LowLevel.mk_string_symbol("model_eval_probe_set"),
        LowLevel.mk_finite_set_sort(IntSort.new),
      )

      solver = Solver.new
      VeryLowLevel.Z3_solver_assert(_ctx, solver._solver, VeryLowLevel.Z3_mk_finite_set_member(_ctx, _seven, _set))
      expect(solver.check).to eq(:sat)
      model = solver.model

      # The model pins `s` down completely - no `set.unique` anywhere in it
      _value = LowLevel.model_get_const_interp(model, model.consts[0])
      expect(LowLevel.ast_to_string(Struct.new(:_ast).new(_value))).to eq("(set.singleton 7)")

      # ...and the evaluator still won't reduce either question about it. A literal
      # would be `:numeral` - `:app` means the term came back as it went in.
      [
        VeryLowLevel.Z3_mk_finite_set_member(_ctx, _seven, _set),
        VeryLowLevel.Z3_mk_finite_set_size(_ctx, _set),
      ].each do |_query|
        answer = Expr.new_from_pointer(LowLevel.model_eval(model, Expr.new_from_pointer(_query), true))
        expect(answer.ast_kind).to eq(:app)
      end
    end

    # The workaround for the above, and the reason a finite set `#value` is possible at
    # all: the simplifier does know these rules, even though the evaluator doesn't.
    #
    # It costs nothing to reach, because every `#value` in the gem already falls back to
    # `#simplify` when the term isn't already a literal - so the answers `model_eval`
    # refused above come out right anyway, by a route that was there for other reasons.
    #
    # It's a partial workaround though: the simplifier gives up on `set.size` of a
    # union of two concrete singletons, which is 2 and not hard. Pinned here rather
    # than assumed, because a reader built on this has to be ready to raise.
    it "Z3_simplify evaluates the finite set operations Z3_model_eval won't" do
      skip "Finite sets were added in Z3 5.0" unless Z3.version_at_least?(5, 0)
      _ctx = LowLevel._ctx_pointer
      _int = IntSort.new._ast
      _seven = VeryLowLevel.Z3_mk_numeral(_ctx, "7", _int)
      _eight = VeryLowLevel.Z3_mk_numeral(_ctx, "8", _int)
      _singleton = VeryLowLevel.Z3_mk_finite_set_singleton(_ctx, _seven)

      # #value simplifies on its own, so these are the unreduced terms model_eval hands
      # back, answered the way any other expression would be
      expect(Expr.new_from_pointer(VeryLowLevel.Z3_mk_finite_set_size(_ctx, _singleton)).value).to eq(1)
      expect(Expr.new_from_pointer(VeryLowLevel.Z3_mk_finite_set_member(_ctx, _seven, _singleton)).value).to be true
      expect(Expr.new_from_pointer(VeryLowLevel.Z3_mk_finite_set_member(_ctx, _eight, _singleton)).value).to be false

      # Where it gives up. Asserting the term is still `:app` rather than that #value
      # raises, because building that error message would print the term, and printing
      # walks into the missing sort kind two examples up.
      _union = VeryLowLevel.Z3_mk_finite_set_union(
        _ctx, _singleton, VeryLowLevel.Z3_mk_finite_set_singleton(_ctx, _eight),
      )
      _size = VeryLowLevel.Z3_mk_finite_set_size(_ctx, _union)
      expect(Expr.new_from_pointer(VeryLowLevel.Z3_simplify(_ctx, _size)).ast_kind).to eq(:app)
    end

    # `set.size` is unsound. Z3 never connects element distinctness to cardinality, so
    # it will agree that a set it can see has two elements has one - and hand back a
    # model saying so, which is the shape of this that matters, because the model
    # contradicts the very constraint it claims to satisfy.
    #
    # Membership, equality and subset are all sound - `Set[1] == Set[2]` is unsat and
    # `1 in Set[2]` is unsat - so Z3 knows perfectly well that 1 and 2 are different.
    # It just doesn't tell the cardinality solver.
    #
    # What it does know is the bounds: a union of n singletons has a size between 1
    # and n. So `size == 0` and `size == 3` are both correctly refused for a two
    # element set, and only the middle is wrong.
    #
    # `FiniteSetSort`'s documentation warns about this, since there's no working around
    # it - refusing `#size` would leave the sort with no point to it.
    #
    # Only 5.0 gets as far as being unsound about it: 5.1 dies on these queries
    # instead of answering them, which is the example below this one.
    #
    # Correct: unsat, on every one of the three below.
    it "set.size is unsound - a two element set is allowed to have one element" do
      skip "Finite sets were added in Z3 5.0" unless Z3.version_at_least?(5, 0)
      skip "Z3 5.1 crashes on these queries rather than answering them" unless Z3.version_at_least?(5, 2)
      sort = FiniteSetSort.new(IntSort.new)
      set = sort.var("unsound_size_set")

      # The whole set is spelled out, so there is nothing left to decide
      solver = Solver.new
      solver.assert set == Set[1, 2]
      solver.assert set.size == 1
      expect(solver.check).to eq(:sat)
      # ...and the model it offers says the set is `Set[1, 2]`, whose size is 2
      expect(solver.model[set].value).to eq(Set[1, 2])

      # Same thing reached through membership rather than equality
      solver = Solver.new
      solver.assert set.include?(7)
      solver.assert set.include?(9)
      solver.assert set.size == 1
      expect(solver.check).to eq(:sat)

      # Ground, with no variable in it at all
      solver = Solver.new
      solver.assert sort.from_const(Set[1, 2, 3]).size == 2
      expect(solver.check).to eq(:sat)

      # The bounds it does get right, so this is a gap and not a total absence
      [0, 4].each do |wrong_size|
        solver = Solver.new
        solver.assert sort.from_const(Set[1, 2, 3]).size == wrong_size
        expect(solver.check).to eq(:unsat)
      end
    end

    # 5.1 doesn't answer a `set.size` question about a set whose elements it can see -
    # it dies. A ground set segfaults; one reached through a variable trips an
    # assertion violation in ast.cpp and exits 114. Either way the process is gone, so
    # this has to run somewhere else, and every other example asking `#size` about a
    # concrete set skips below 5.2.
    #
    # It's specifically a set Z3 can see the elements of. `set.unique` sets - the ones
    # it only had to decide a size for - still answer, which is why `#empty?` and the
    # rest of the sort are usable on 5.1 at all.
    #
    # Correct: an answer, even the unsound one 5.0 gives, rather than a dead process.
    it "set.size crashes the process for a set with known elements" do
      skip "Finite sets were added in Z3 5.0" unless Z3.version_at_least?(5, 0)
      expect(dies_on_a_signal?(<<~RUBY)).to be true
        sort = Z3::FiniteSetSort.new(Z3::IntSort.new)
        solver = Z3::Solver.new
        solver.assert sort.from_const(Set[1, 2, 3]).size == 2
        solver.check
      RUBY
    end

    # Equality is unsound once a `set.range` has a symbolic end. Z3 will agree that
    # `(1..n)` is `Set[1, 2, 3]` while refusing to let `n` be 3, and offer an `n` for
    # which the two sets plainly differ.
    #
    # It's specifically equality: membership stays sound with a symbolic end, and
    # equality stays sound with literal ones, so the ordinary uses of `#Range` are
    # fine. `FiniteSetSort#Range`'s spec asks about membership for this reason.
    #
    # Correct: unsat, since `(1..n) == Set[1, 2, 3]` forces `n` to be 3.
    it "set.range equality is unsound when an end is symbolic" do
      skip "Finite sets were added in Z3 5.0" unless Z3.version_at_least?(5, 0)
      sort = FiniteSetSort.new(IntSort.new)
      n = Z3.Int("unsound_range_n")

      solver = Solver.new
      solver.assert sort.Range(1, n) == Set[1, 2, 3]
      solver.assert n != 3
      expect(solver.check).to eq(:sat)
      # ...and the `n` it picks makes a range which is not that set at all
      expect(solver.model[n].value).to_not eq(3)

      # With both ends literal it decides correctly, in both directions
      solver = Solver.new
      solver.assert sort.Range(1, 2) == Set[1, 2, 3]
      expect(solver.check).to eq(:unsat)

      solver = Solver.new
      solver.assert sort.Range(1, 3) == Set[1, 2, 3]
      expect(solver.check).to eq(:sat)

      # ...and membership is sound even with a symbolic end
      solver = Solver.new
      solver.assert sort.Range(1, n).include?(3)
      solver.assert n == 2
      expect(solver.check).to eq(:unsat)
    end

    # `set.map` doesn't answer. Not slowly, not `:unknown` - `#check` never returns,
    # and `timeout` and `rlimit` both go unread, so nothing short of killing the
    # process gets control back. It happens on questions with nothing to them: whether
    # 10 is in `Set[1, 2].map { |x| x * 10 }`, or whether two identical map terms are
    # equal.
    #
    # `FiniteSetExpr#map` refuses to build one for exactly this reason - a term that
    # stops the next `#check` is worse than no term - so this reproduces it through
    # LowLevel to get past that guard. `FiniteSetExpr::MAP_HANGS` is what to change
    # when this example starts failing.
    #
    # `set.filter` is fine, in the sense that matters here: it answers `:unknown` a
    # lot, but it answers.
    #
    # Correct: any answer at all, including `:unknown`.
    it "set.map hangs the solver, ignoring timeout and rlimit" do
      skip "Finite sets were added in Z3 5.0" unless Z3.version_at_least?(5, 0)
      expect(hangs?(<<~RUBY)).to be true
        sort = Z3::FiniteSetSort.new(Z3::IntSort.new)
        set = sort.from_const([1, 2])
        x = Z3::IntSort.new.fresh_var("x")
        # #map refuses to build this, so it's built the way #map would have
        mapped = sort.new(Z3::LowLevel.mk_finite_set_map(Z3.Lambda(x, x * 10), set))
        solver = Z3::Solver.new(timeout: 1000, rlimit: 10000)
        solver.assert mapped.include?(10)
        solver.check
      RUBY
    end

    it "set.filter answers, which is what makes #select usable and #map not" do
      skip "Finite sets were added in Z3 5.0" unless Z3.version_at_least?(5, 0)
      sort = FiniteSetSort.new(IntSort.new)
      filtered = sort.from_const([1, 2, 3]).select { |x| x > 1 }

      solver = Solver.new
      solver.assert filtered.include?(1)
      expect(solver.check).to eq(:unsat)

      # Incomplete rather than wrong - it can't confirm the ones it can't refute
      solver = Solver.new
      solver.assert filtered.include?(2)
      expect(solver.check).to eq(:unknown)
    end
  end
end
