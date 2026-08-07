# Ruby bindings for Z3

This is a Ruby interface for [Z3](https://github.com/Z3Prover/z3).

Recommended [Z3](https://github.com/Z3Prover/z3) version is 4.16 or newer. Make sure you have it first (e.g. `brew install z3` on MacOS).

```sh
gem install z3
```

[API documentation is here](https://taw.github.io/z3/).

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
    [zvar.to_s, zvalue.value]
  end

  p hash
  # {"a" => 2, "b" => 1}
end
```

## Interface

The public interface is various methods in `Z3` module, and on objects created by it.

The [`examples/`](https://github.com/taw/z3/blob/master/examples) directory is probably the best place to start.

You can use most Ruby operators to construct Z3 expressions, but use `| &` instead of `|| &&` for boolean operators. They unfortunately have wrong operator precedence so you'll need to use some extra parentheses.

`Z3.Function` declares an uninterpreted function - a symbol the solver decides the meaning of. The last sort is the range, the ones before it the domain, and you apply it with `[]`:

```ruby
f = Z3.Function("f", Z3::IntSort.new, Z3::IntSort.new)
solver.assert f[f[x]] == x
solver.assert f[x] != x
```

`Z3::EnumSort` declares an enumeration - a sort whose values are a fixed list of names, and nothing else. The values are Symbols, and they work anywhere that sort is expected:

```ruby
color = Z3::EnumSort.new("Color", %i[red green blue])
x, y = color.var("x"), color.var("y")
solver.assert x != y
solver.assert x != :red
solver.model[x].value   # => :green
```

A `Seq` maps and folds, with a block, the way a Ruby Array does. The block gets Z3 expressions and returns one, and the result is a term rather than an answer - so the interesting direction is backwards, asking the solver for a sequence with the property you want:

```ruby
xs.map { |x| x * 2 }                              # Seq(Int) -> Seq(Int)
xs.map { |x| x > 1 }                              # ...and to Seq(Bool)
xs.inject(0) { |acc, x| acc + x }                 # Int
xs.map_with_index { |i, x| x * 10 + i }           # index first, Z3's order
xs.inject_with_index(0) { |i, acc, x| acc + x * i }

solver.assert xs.length == 3                      # solve for the sequence itself
solver.assert(xs.inject(0) { |acc, x| acc + x } == 10)
```

`#reduce` is `#inject`, as in Ruby, and `#mapi` / `#fold_left` / `#fold_lefti` are aliases under Z3's own names. `map_with_index` and `inject_with_index` take `from:` to start the index somewhere other than 0, which Ruby has no spelling for. Instead of a block you can pass a function: `#map` takes a `Z3.Lambda`, and the other three take a `Z3::SeqFunction`, which is what a lambda of two or three arguments has to be until multi-dimensional array sorts exist. A String is a `Seq(Char)` so it maps and folds too, but Z3 will not evaluate the result - see `StringExpr` for what that costs.

Enums don't share a namespace, so `Color` and `Squirrel` can both have a `:red` and the two are different values of different sorts, which Z3 won't compare. Unlike every other sort an enumeration can only be declared once - Z3 rejects a second declaration of the same name - so asking for the same one again gives back the sort you already have, and asking for the same name with different values raises.

`Z3::TupleSort` declares a tuple - a record of named fields, each with a sort of its own. Fields read as methods, and a value converts to a Hash:

```ruby
point = Z3::TupleSort.new("Point", x: Z3::IntSort.new, y: Z3::IntSort.new)
p = point.var("p")
solver.assert p.x > 0
solver.assert p == point.mk(3, 4)   # or p == [3, 4], or p == {x: 3, y: 4}
solver.model[p].value               # => {x: 3, y: 4}
```

A tuple is a sort like any other, so tuples nest, key an `Array`, and are the way to have an uninterpreted function take or return more than one value. `p[:x]` reads a field as well, which is how to read one named after something an expression already answers to, like `sort` or `value` - those don't get a method of their own.

Tuples are declared once, like enums, and share the datatype namespace with them, so neither can take a name the other has. The reason is worse than the enum's: where Z3 rejects a second enum of the same name outright, it accepts a second *tuple* and quietly rebuilds the sort's fields from it, abandoning every term built against the first declaration. Asking for the same tuple twice gives back the sort you already have; the same name with different fields raises.

A model reports an uninterpreted function as a Hash from argument lists to values, with Ruby's Hash default holding Z3's `else` branch - the answer for every argument the solver never had to pin down. Z3 picks one of the values as that fallback, so the entries are only the exceptions to it:

```ruby
# after asserting f[1] == 10 and f[2] == 20
interp = model.func_interp(f)   # {[2] => 20}
interp.default                  # 10 - which is also the answer for f[1] and f[999]
model.to_s                      # Z3::Model<f={(2) => 20, else => 10}>
```

`Model#each` walks constants and functions alike; `#each_const` and `#each_func` take one kind at a time. For an `UninterpretedSort`, `#sorts` and `#sort_universe` give the elements the model had to invent.

To get a Ruby object back out of a Z3 expression, use `#value`. It works on any expression Z3 can reduce to a literal - most usefully the ones you get out of a model - and raises otherwise:

```ruby
Z3.Const(42).value                          # 42
Z3.Const(true).value                        # true
Z3::StringSort.new.from_const("hi").value   # "hi"
Z3.Int("a").value                           # raises - "a" is not a literal
```

A `Bitvec` carries no sign of its own, so it has `#signed_value` and `#unsigned_value` instead - the same eight bits are `200` read one way and `-56` the other. `Real` has no `#value`, as Z3's Reals include the algebraic numbers and √2 has no exact Ruby equivalent at all - `#to_r` is exact and refuses when it can't be, `#to_f` approximates and says so by being a Float.

A Ruby Float *is* an IEEE double, so `Float`'s `#value` converts every `Float(11, 53)` or narrower literal exactly, NaN, the infinities and the two zeroes included. A wider sort raises whatever it holds - a quadruple's `1.5` would convert exactly, but a sort a Float can't round-trip doesn't get a `#value` which works only for the values which happen to be small enough.

The container sorts hand back the matching Ruby container, calling `#value` on what's inside, so a `Seq(Seq(Int))` gives nested Arrays:

```ruby
seq_expr.value     # => [1, 2, 3]
set_expr.value     # => #<Set: {3, 5}>
array_expr.value   # => {2 => 7}, with 0 as the Hash default
```

An `Array` is a total map, so its entries alone can't say what it is - Ruby's Hash default holds `#default`, the answer for every key not listed, the same shape a function interpretation uses. A `Set` is an `Array` to Bool, which means Z3 is just as happy answering "everything except 5" as it is "3 and 5". Ruby has no co-finite set, so that case raises rather than lying about it, and `#complement` is how you ask which elements it leaves out.

Note that `#value` is not the same as `#to_i` and friends. `#value` leaves Z3 and hands you a Ruby object, while `#to_i`, `#to_bv` and so on build a *new Z3 expression* of another sort - `string_expr.to_i` is the symbolic `str.to_int`, not a Ruby Integer. On `Int` the two are the same method, since converting an Int to an Int can't mean anything else.

Ruby's implicit conversion methods - `to_str`, `to_int`, `to_ary`, `to_hash`, `to_proc` - are deliberately **not** defined on expressions. Ruby calls those on its own whenever it wants that exact type, and no Z3 expression can promise to be one.

The interface is potentially unstable, and can change in the future.

`Z3::VeryLowLevel` and `Z3::LowLevel` are FFI interfaces for internal use, and they shouldn't be used directly. Also don't use any method starting with `_`. Doing this is likely to lead to segmentation faults unless extreme care is taken.

A utility at `api/gen_api` will loop through a .h file and generate Ruby definitions. This will update the API when upstream changes `z3_api.h`

## Limitations

`==` on an expression builds a `Z3::BoolExpr` rather than answering `true` or `false`, and every `BoolExpr` is truthy:

```ruby
a = Z3.Int("a")
b = Z3.Int("b")
a == b     # => Bool<a = b>, not false
```

That's the whole point of the gem, and Ruby's core classes are patched so the expression can be on either side - `1 == a` builds the same equation `a == 1` does, and so do `true`, `"a"`, `:red`, `[1, 2]` and `{x: 1, y: 2}` against the sorts which can hold them. The cost is that anything asking `==` a question and expecting a Ruby answer gets an expression instead, which reads as "yes".

### Containers which work

Hash and Set look their keys up with `#hash` and `#eql?`, not with `==`, and expressions answer those properly. Z3 interns its ASTs, so two expressions are `eql?` exactly when they're the same term - and being built separately doesn't make them different:

```ruby
{a => 1, b => 2}[b]      # => 2
Set[a, b].include?(c)    # => false
[a, b].uniq              # => [a, b]
[a, a].uniq              # => [a]
(a + 1).eql?(a + 1)      # => true
(a + 1).eql?(1 + a)      # => false - a different term, not a different value
```

So Hash reading and writing, `#key?`, Set membership, and the Array operations built on hashing - `#uniq`, `#-`, `#&`, `#|`, `#tally`, `#group_by` - all behave as you'd expect. `#eql?` is also how you ask whether two expressions are the same term, which is the question `==` would have answered in a library that wasn't this one.

This is where the Ruby gem differs from [crystal-z3](https://github.com/taw/crystal-z3), where Hash and Set have the problem too - Crystal has no `eql?`, so `==` has to do both jobs at once.

### Containers which don't

Anything which searches with `==` stops at the first thing it looks at, and anything which counts or deletes by `==` matches everything:

```ruby
[a] == [b]           # => true
[a].include?(b)      # => true, for any b
[a, b].index(b)      # => 0
[a, b].count(b)      # => 2
[a, b].delete(b)     # removes both
{x: a} == {x: b}     # => true - Hash#== compares its values with ==
{1 => a}.value?(b)   # => true
```

`case`/`when` goes the same way, because `Object#===` is `==` unless a class says otherwise, so the first branch mentioning an expression always wins. So does ordering: `Object#<=>` answers `0` whenever `==` is truthy, which makes every expression compare equal to every other, and `#sort`, `#min` and `#max` quietly hand back the order they were given.

Building these collections is fine. It's only reading from them which lies, and `#eql?` reads correctly - `[a, b].index{|x| x.eql?(b)}` is `1`.

The same applies with the Ruby value on the left, since that's the half the patched core classes make work: `[1].include?(a)` is `true`. Hashing is unaffected there too, so `Set[1].include?(a)` is `false` and `{1 => :x}[a]` is `nil`.

### nil

`nil` isn't a Z3 value, and it's the one case left where the two sides disagree:

```ruby
a == nil    # raises Z3::Exception
nil == a    # => false
```

`NilClass` is deliberately not patched. Making it match would mean raising, and Ruby asks `nil == x` on its own, in places where an exception would stop the whole call rather than the element - `[nil, 1].include?(a)` asks it of the first element before going on to the second. Plain `Object`s are left alone for the same reason.

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
