# Ruby bindings for Z3

This is a Ruby interface for [Z3](https://github.com/Z3Prover/z3).

Recommended [Z3](https://github.com/Z3Prover/z3) version is either 4.16 or 5.x. Make sure you have it first (e.g. `brew install z3` on OSX). Even if you use very old version of Z3 library, all basic functionality will still work.

```sh
gem install z3
```

[**API.md**](API.md) is the guide to everything the gem implements, and the
[API documentation is here](https://taw.github.io/z3/).

## Basic usage

Variables are initialized with `Z3.Bool`, `Z3.Int`, `Z3.Real`, `Z3.Bitvec`.

Constrain and solve with `Z3::Solver` and `Z3::Optimize`.

```ruby
require "z3"

# make z3 variables
a, b = Z3.Int("a"), Z3.Int("b")

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
    [zvar.to_s, zvalue.value]
  end

  p hash
  # {"a" => 2, "b" => 1}
end
```

The [`examples/`](https://github.com/taw/z3/blob/master/examples) directory is probably the best place to start.

## The basics

You can use most Ruby operators to construct Z3 expressions, but use `|` `&` instead of `||` `&&` for boolean operators. They unfortunately have different operator precedence so you'll need to use some extra parentheses.

```ruby
x, y = Z3.Int("x"), Z3.Int("y")
p, q  = Z3.Bool("p"), Z3.Bool("q")

x + 2 * y <= 10
(p | q) & ~(p & q)
Z3.IfThenElse(x > 0, x, -x)
```

`Z3::Solver` collects constraints and answers questions about them:

```ruby
solver = Z3::Solver.new
solver.assert x > 0
solver.assert x < 10

solver.check           # :sat, :unsat, or :unknown
solver.satisfiable?    # true
solver.model           # only after a successful check
solver.push            # save the current constraints...
solver.pop             # ...and go back to them
```

`Z3::Optimize` is the same thing with objectives - it maximizes or minimizes a term
instead of just satisfying the constraints:

```ruby
opt = Z3::Optimize.new
opt.assert x >= 0
opt.assert y >= 0
opt.assert x + y <= 10
opt.maximize(x * 2 + y)
opt.satisfiable?       # true
opt.model.to_s         # Z3::Model<x=10, y=0>
```

A model says what each variable is. Index it with a variable, and use `#value` to get
a plain Ruby object back:

```ruby
model[x]         # Int<10>, still a Z3 expression
model[x].value   # 10, a Ruby Integer
model.to_s       # Z3::Model<x=10, y=0>
model.each { |var, val| puts "#{var} = #{val}" }
```

`#value` works on anything Z3 can reduce to a literal - most usefully what comes out
of a model - and raises otherwise. A `Bitvec` has `#signed_value` and `#unsigned_value`
instead, since the same eight bits are `200` read one way and `-56` the other, and a
`Real` has `#to_r` (exact, and refuses when it can't be) and `#to_f` (approximate)
because Z3's Reals include irrational numbers.

## The one thing to know

`==` on an expression builds a `Z3::BoolExpr` rather than answering `true` or `false`,
and every `BoolExpr` is truthy:

```ruby
a = Z3.Int("a")
b = Z3.Int("b")
a == b     # => Bool<a = b>, not false
a.eql?(b)  # => false - this is the one which answers
```

That's the whole point of the gem, and Ruby's core classes are patched so the
expression can be on either side - `1 == a` builds the same equation `a == 1` does.
The cost is that anything asking `==` a question and expecting a Ruby answer gets an
expression instead, which reads as "yes": `[a].include?(b)` is `true` for any `b`, and
so is `[a] == [b]`.

Hash and Set are fine, because they look keys up with `#hash` and `#eql?` -
`{a => 1, b => 2}[b]` is `2`. `nil == a` is `false` while `a == nil` raises. There's a
[fuller account in API.md](API.md#ruby-integration-and-its-limits), and it's worth
reading before debugging something strange.

## What else is in here

Everything below is covered in [**API.md**](API.md):

* Sorts beyond the basic four: [Floats and rounding modes](API.md#floats-and-rounding-modes),
  [Strings and Chars](API.md#strings-and-chars), [Sequences](API.md#sequences),
  [regular expressions](API.md#regular-expressions), [Arrays and Sets](API.md#arrays-and-sets),
  [finite sets](API.md#finite-sets), [enums and tuples](API.md#enums-and-tuples),
  [datatypes](API.md#datatypes), [uninterpreted sorts](API.md#uninterpreted-sorts-finite-domains-type-variables)
* [Functions](API.md#functions), including recursive definitions, and
  [quantifiers and lambdas](API.md#quantifiers-and-lambdas)
* The rest of [Solver](API.md#solver) - unsat cores, assumptions, consequences,
  SMT-LIB2 input - and of [Model](API.md#model) and [Optimize](API.md#optimize)
* [Tactics, probes, goals and simplifiers](API.md#tactics-probes-goals-simplifiers)
* [Parameters and statistics](API.md#parameters-and-statistics)

The interface is potentially unstable, and can change in the future.

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
