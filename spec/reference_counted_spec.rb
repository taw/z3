require "weakref"

# Z3's non-AST objects are reference counted, so every wrapper claims its object
# and releases it from a finalizer. Two things can go wrong: releasing an object
# that's still in use, and building a finalizer that closes over the wrapper,
# which keeps the wrapper alive forever so nothing is ever released.
module Z3
  describe ReferenceCounted do
    let(:x) { Z3.Int("x") }

    # Each entry builds a fresh object, and reads it in a way that goes back into Z3
    subjects = {
      "Solver" => [
        ->(x) { Z3::Solver.new.tap { |s| s.assert(x == 3) } },
        ->(s) { s.satisfiable? },
        true,
      ],
      "Optimize" => [
        ->(x) { Z3::Optimize.new.tap { |o| o.assert(x == 3) } },
        ->(o) { o.satisfiable? },
        true,
      ],
      "Model" => [
        ->(x) { Z3::Solver.new.tap { |s| s.assert(x == 3); s.check }.model },
        ->(m) { m.to_s },
        "Z3::Model<x=3>",
      ],
      "Goal" => [
        ->(_x) { Z3::Goal.new },
        ->(g) { g.size },
        0,
      ],
      "Tactic" => [
        ->(_x) { Z3::Tactic.skip },
        ->(t) { t.help.class },
        String,
      ],
      "Probe" => [
        ->(_x) { Z3::Probe.new("is-qfbv") },
        ->(p) { p.apply(Z3::Goal.new) },
        1.0,
      ],
      "Params" => [
        ->(_x) { Z3::Params.new(timeout: 10) },
        ->(p) { p.to_s },
        "(params timeout 10)",
      ],
      # These outlive the Solver they came from, so they need their own claim on it
      "ParamDescrs" => [
        ->(_x) { Z3::Solver.new.param_descrs },
        ->(d) { d.include?("timeout") },
        true,
      ],
    }

    subjects.each do |name, (build, read, expected)|
      describe name do
        it "is not released while it is still referenced" do
          kept = build.call(x)
          # Churn through short-lived objects of every kind, so finalizers run
          50.times do
            s = Z3::Solver.new
            s.assert(x > 0)
            s.check
            s.model
            Z3::Optimize.new
            Z3::Goal.new
            Z3::Tactic.skip
            Z3::Probe.new("is-qfbv")
            Z3::Params.new(timeout: 10)
            s.param_descrs
          end
          3.times { GC.start }
          expect(read.call(kept)).to eq(expected)
        end

        it "is collectable once dropped" do
          # Built on a throwaway thread, as Ruby scans the machine stack
          # conservatively, and a leftover slot pointing at an intermediate object
          # (a Solver still memoizing its Model, say) would falsely keep it alive
          ref = nil
          Thread.new { ref = WeakRef.new(build.call(x)) }.join
          5.times { GC.start(full_mark: true, immediate_sweep: true) }
          # A finalizer closing over the wrapper would keep it alive here,
          # and then nothing would ever be released
          expect(ref.weakref_alive?).to be_falsey
        end
      end
    end
  end
end
