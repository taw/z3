This is Ruby interface for Z3 [ https://github.com/Z3Prover/z3 ].

It's in extremely early stages of development. Pull requests always welcome.

### Interface

`Z3::Core` is low level FFI interface, and it shouldn't be used directly.

The rest of `Z3` is high level API, but the interface is extremely unstable at this point, and it's pretty much guaranteed to  change many times.

You can use most Ruby operators to construct ASTs, but use `~ | &` instead of `! || &&` for boolean operators.

### Requirements

To use it, you'll need to install `z3`. On OSX that would be:

    brew install z3

On other systems use appropriate package manager.
