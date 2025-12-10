# Ruby bindings for Z3

This is a Ruby interface for [Z3](https://github.com/Z3Prover/z3).

Minimum required [Z3](https://github.com/Z3Prover/z3) version is 4.8. Make sure you have it first (e.g. `brew install z3` on MacOS).

It's in very early stages of development. Pull requests always welcome.

```sh
gem install z3
```

## Basic usage

Variables are initialized with `Z3.Bool`, `Z3.Int`, `Z3.Real`, `Z3.Bitvec`.

Constrain and solve with `Z3::Solver` and `Z3::Optimize`.

```ruby
require 'z3'

# make z3 variables
a, b = Z3.Int('a'), Z3.Int('b')

# add constraints with expressions
solver = Z3::Solver.new
solver.assert(a > 1)
solver.assert(b > 0)
solver.assert(a + b == 3)

# check sat, find model
if solver.satisfiable?
  model = solver.model
  
  # convert z3 model to ruby types
  hash = model.to_h do |zvar, zvalue| 
    [zvar.to_s, zvalue.to_i] 
  end
  
  p hash
  # {"a" => 2, "b" => 1}
end
```

## Interface

The public interface is various methods in `Z3` module, and on objects created by it.

The [`examples/`](https://github.com/taw/z3/blob/master/examples) directory is probably the best place to start.

You can use most Ruby operators to construct Z3 expressions, but use `| &` instead of `|| &&` for boolean operators. They unfortunately have wrong operator precedence so you'll need to use some extra parentheses.

The interface is potentially unstable, and can change in the future.

`Z3::VeryLowLevel` and `Z3::LowLevel` are FFI interfaces for internal use, and they shouldn't be used directly. Also don't use any method starting with `_`. Doing this is likely to lead to segmentation faults unless extreme care is taken.

A utility at `api/gen_api` will loop through a .h file and generate Ruby definitions. This will update the API when upstream changes `z3_api.h`

## Building

```
brew install z3
rake gem:build
bundle install
rake spec
```

### Known Issues

As Z3 is a C library, doing anything weird with it will segfault your process. Ruby API tries its best to prevent such problems and turn them into exceptions instead, but if you do anything weird (especially touch any method prefixed with `_` or `Z3::LowLevel` interface), crashes are possible. If you have reproducible crash on reasonable looking code, definitely submit it as a bug, and I'll try to come up with a workaround.

As Z3 mixes aggressively interning ASTs and reference counting, it's not very compatible with Ruby style memory management, so memory will leak a good deal. It's usually not much worse than the usual Symbol memory leak, but you might want to avoid Z3 in a long running processes exposed to public input.

### Python examples

Some of example solvers also have Python versions available from https://github.com/taw/puzzle-solvers
