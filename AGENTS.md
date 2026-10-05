# AGENTS.md

Ruby bindings for the [Z3](https://github.com/Z3Prover/z3) SMT solver, via `ffi`.
Supported Z3: 4.16 and 5.x (CI runs 4.16, local dev is usually latest Homebrew 5.x).

## Layout

- `lib/z3.rb` - requires everything, order matters
- `lib/z3/very_low_level.rb` - raw FFI; hand-written `attach_function`s for signatures `gen_api` can't express
- `lib/z3/low_level.rb` - unwraps Ruby objects to pointers, threads the singleton context; hand-written wrappers
- `lib/z3/*_auto.rb` - **generated, never edit by hand** (`rake api`)
- `lib/z3/sort/`, `lib/z3/expr/` - one class per sort / expression kind
- `lib/z3/interface.rb` - `Z3.Int`, `Z3.Bool`, `Z3.version_at_least?` etc. (the public module functions)
- `lib/z3/hacks.rb` - monkeypatches on Integer/Float/etc. so `1 == expr` works
- `api/` - `definitions.h` (extracted from Z3 headers), `gen_definitions`, `gen_api` (with its skip list of functions we deliberately never bind)
- `spec/*_spec.rb` - unit specs; `spec/integration/` - runs each `examples/*` script and compares output (often against `examples/*-N.txt` puzzle inputs)
- `spec/upstream_bugs_spec.rb` - pins known Z3 bugs so we notice when they're fixed
- `examples/` - puzzle solvers and demos, the best real-world usage reference
- `README.md` (short basics), `API.md` (full guide, one chapter per area), `docs/` (generated rdoc)
- `_TODO.md` (missing-functionality survey), `_PROOF.md` (proof API sketch) - working notes

## Commands

```sh
bundle exec rspec                   # everything; slow (integration), allow ~10 min
bundle exec rspec spec/foo_spec.rb  # one file
rake spec:unit / rake spec:integration
rake api                            # regen definitions.h + *_auto.rb from installed brew z3
rake rdoc                           # regen docs/
rake coverage:missing               # list bound but unused C APIs
```

## Conventions

- Public API should feel like Ruby, not transliterated C. Prefer operators, `[]`, blocks, `#value` returning Ruby types. If it can't be made Ruby-ish, it may belong only in `LowLevel`.
- One global `Z3::Context` singleton; multiple contexts are explicitly out of scope.
- Version-gate newer Z3 features with `Z3.version_at_least?(5, 0)`: the gem must still load and work on 4.16, and only raise when 5.x-only functionality is actually used. Missing C functions become stubs that raise `Z3::Exception`.
- Don't map Z3 C enums to symbols by hard-coded numbers - they change between Z3 versions.
- Specs: don't assert via stringification (except printer specs); check semantics with the solver. Gate version-specific specs with `skip ... unless Z3.version_at_least?(...)`. Avoid flaky solver-dependent outputs.
- Upstream Z3 bugs: work around them in lib, document briefly in a comment pointing at `spec/upstream_bugs_spec.rb`, and add a pinning spec there (with `fixed_in` where workarounds are conditional).
- New user-facing functionality: add specs, document in `API.md` (and `README.md` only if it's basics), add rdoc comments.
- Match surrounding style: 2-space indent, double quotes, sparse comments that explain *why*.
