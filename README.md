This is Ruby interface for Z3 [ https://github.com/Z3Prover/z3 ].

It's in extremely early stages of development. Pull requests always welcome.

### Interface

`Z3::VeryLowLever` / `Z3::LowLevel` are low level FFI interface, and they shouldn't be used directly.

The rest of `Z3` is high level API, but the interface is extremely unstable at this point, and it's pretty much guaranteed to  change many times. Check specs or `examples/` directory for usage.

You can use most Ruby operators to construct Z3 expressions, but use `~ | &` instead of `! || &&` for boolean operators. They unfortunately have wrong operator precedence so you'll need to use some extra parentheses.

As for API internals, attributes starting with `_` are FFI internals you shouldn't touch, other attributes are generally legitimate Ruby objects.

Bit vectors are treated as signed by default. [well, mostly, more systematic treatment of this is on TODO list]

### Requirements

To use it, you'll need to install `z3`. On OSX that would be:

    brew install z3

On other systems use appropriate package manager.

### Known Bugs

Ruby API tries to catch the most common mistakes, but if you use API in a weird way you can get C crash instead of nice Ruby exception.

Memory will leak a good deal. Generally avoid in long running processes.
