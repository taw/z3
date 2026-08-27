# Z3 gem API guide

Everything the gem implements, one chapter per area. [The README](README.md) covers
the basics - variables, solver, model, optimize - and this is the rest of it.

The generated method-by-method documentation is at <https://taw.github.io/z3/>, and
the [`examples/`](https://github.com/taw/z3/blob/master/examples) directory is real
code using most of this.

* [Names](#names)
* [Sorts and variables](#sorts-and-variables)
* [Expressions](#expressions)
* [Booleans](#booleans)
* [Integers and Reals](#integers-and-reals)
* [Bitvectors](#bitvectors)
* [Floats and rounding modes](#floats-and-rounding-modes)
* [Strings and Chars](#strings-and-chars)
* [Sequences](#sequences)
* [Regular expressions](#regular-expressions)
* [Arrays and Sets](#arrays-and-sets)
* [Finite sets](#finite-sets)
* [Enums and Tuples](#enums-and-tuples)
* [Datatypes](#datatypes)
* [Uninterpreted sorts, finite domains, type variables](#uninterpreted-sorts-finite-domains-type-variables)
* [Functions](#functions)
* [Quantifiers and lambdas](#quantifiers-and-lambdas)
* [Solver](#solver)
* [Model](#model)
* [Optimize](#optimize)
* [Tactics, probes, goals, simplifiers](#tactics-probes-goals-simplifiers)
* [Parameters and statistics](#parameters-and-statistics)
* [Ruby integration and its limits](#ruby-integration-and-its-limits)
* [Global settings and internals](#global-settings-and-internals)

## Names

Z3's vocabulary comes from mathematical logic, and some of it means something else in
Ruby. Methods mostly follow Ruby - `include?`, `start_with?`, `sub`, `inject` - so
this is mostly about the nouns.

**sort** is a type. `Z3::IntSort` is the type Int; nothing here sorts anything.

**assert** adds a constraint to the solver, and has nothing to do with tests.

**model** is one solution: an assignment of values which satisfies the constraints.

**distinct** is pairwise `!=`, across any number of arguments at once.

**const** is a variable. Logic calls a name whose value gets picked a constant, which
is what a programmer calls a variable, so the gem says `var` for that and keeps
`const` for the other meaning:

```ruby
sort.var("x")            # a variable
sort.from_const(3)       # a literal
```

Int, Bool, String and Float mean what you'd expect, and `#value` hands back the Ruby
object. Real and Bitvec don't quite: Z3's reals are exact and include the algebraic
numbers, so `√2` is an ordinary Real with no Ruby equivalent, and a Bitvec is fixed
width and carries no sign of its own, which is why `b < c` raises rather than guess and
makes you pick `signed_lt` or `unsigned_lt`.

### Array, Set, FiniteSet

The three most likely to mislead.

An **Array** is a total function from one sort to another - no length, no bounds, no
order, and defined at every index there is. Ruby's nearest thing is a Hash with a
default.

A **Set** is a mathematical set, and may be infinite. It's a membership test rather
than a collection, so it has no `#size`, and "all the even numbers" is an ordinary
value of one:

```ruby
x = Z3.Int("x")
evens = Z3.Lambda([x], (x % 2) == 0)   # a lambda from Int to Bool is a Set(Int)
solver.assert evens.include?(k)
```

A **FiniteSet** is a set in the sense Ruby's `Set` is one - finitely many elements, and
`#size` works. It's usually the one you want.

[Arrays and Sets](#arrays-and-sets), [Finite sets](#finite-sets).

### Capitalised methods

Where Ruby's syntax can't carry an operation, it goes on the class as a capitalised
method, the way Ruby spells its own `Integer()` and `Array()`:

```ruby
Z3::Expr.Eq(a, b)                 # `==` builds an equation rather than answering one
Z3.Distinct(a, b, c)              # no Ruby operator is n-ary
Z3.IfThenElse(c, a, b)
Z3.And(*xs)   Z3.Or(*xs)          # `and` and `or` are keywords, `&` and `|` are binary
Z3.AtMost(xs, 1)                  # no operator at all
Z3::BitvecExpr.UnsignedLt(a, b)   # Ruby has one `<`, and a bitvector needs two
```

Every operator has one of these, so `Z3::ArithExpr.Div(a, b)` is `a / b`, for when the
operator spelling isn't available or isn't clear.

## Sorts and variables

A sort is Z3's word for a type, and in this gem it's an ordinary Ruby object you can
pass around and compare:

```ruby
Z3::IntSort.new          # Int
Z3::BoolSort.new         # Bool
Z3::RealSort.new         # Real
Z3::BitvecSort.new(8)    # Bitvec(8)
Z3::StringSort.new       # String
Z3::FloatSort.new(:double)
Z3::SeqSort.new(Z3::IntSort.new)
Z3::ArraySort.new(Z3::IntSort.new, Z3::BoolSort.new)
```

Sorts are value objects - two `IntSort.new` are `==` and `eql?`, so they work as Hash
keys. Every sort makes variables and literals:

```ruby
sort.var("x")            # a variable of that sort
sort.var(%w[a b c])      # an Array of them, one per name
sort.fresh_var("tmp")    # a variable Z3 names, guaranteed not to collide
sort.from_const(3)       # a literal from a Ruby value
sort.cast(3)             # a literal or a variable, whichever it already is
```

`Z3.Int`, `Z3.Real`, `Z3.Bool`, `Z3.String` and `Z3.Bitvec(name, width)` are shorthand
for `sort.var(name)` on the five sorts you want most often. `Z3.Const(value)` goes the
other way and picks the sort from the Ruby value - `Z3.Const(42)` is an Int, `Z3.Const("hi")`
a String, `Z3.Const(true)` a Bool.

Mixing sorts in one expression coerces towards the wider one, which is what `Sort#>`
answers: Real is wider than Int, and Bitvec, Float and FiniteDomain all claim to be
wider than Int so that a bare Ruby Integer converts into them. Anything that can't
convert raises `Z3::Exception` worded the way Ruby words its own conversion errors -
`Can't convert nil into Int`.

## Expressions

Everything below `Z3::Expr` shares these:

```ruby
e.sort                   # the sort
e == other               # a BoolExpr, not true/false - see the README
e != other
e.to_s                   # Ruby-flavoured printing, "x + 2 * y"
e.sexpr                  # SMT-LIB printing, "(+ x (* 2 y))"
e.inspect                # "Int<x + 2 * y>"
e.value                  # the Ruby value, for literals - raises otherwise
e.simplify(params = {})  # Z3's own rewriter
e.eql?(other)            # same term? - this is the one that answers true/false
e.hash                   # so exprs work in Hash and Set
e.ast_kind               # :numeral, :app, :var, :quantifier, :sort, :func_decl
e.func_decl              # the operator, for an :app
e.arguments              # its arguments
```

`#simplify` takes the rewriter's parameters, which change what it rewrites *towards*:
`som: true` for sum-of-monomials, `arith_lhs: true` to move everything left of a
comparison, `blast_distinct: true` to expand `distinct` into pairwise disequalities.
`Z3.simplify_param_descrs` lists them and `Z3.simplify_help` describes them.

Substitution replaces subterms, all at once, so a swap is a swap:

```ruby
(x + y).substitute(x => 5)              # 5 + y
(x + y).substitute(x => y, y => x)      # swaps rather than doing one after the other
```

`#substitute_functions` matches on the function symbol instead, which inlines a
function everywhere it's applied, including under quantifiers:

```ruby
f = Z3.Function("f", Z3::IntSort.new, Z3::IntSort.new)
(f[x] + f[y]).substitute_functions(f => ->(v) { v * 2 })   # (x * 2) + (y * 2)
```

A value can also be a `FuncDecl` of the same signature, which renames the function, or
any other value, which replaces the application and ignores the arguments. Replacements
aren't applied to each other, so a definition mentioning its own function stops after
one step instead of unfolding forever.

Multi-argument constructors, for when the operator is n-ary and the Ruby operator isn't:
`Z3.Add`, `Z3.Mul`, `Z3.And`, `Z3.Or`, `Z3.Xor`, `Z3.Eq`, `Z3.Distinct`, `Z3.Implies`,
`Z3.IfThenElse`.

`#value` is not `#to_i` and friends. `#value` leaves Z3 and hands you a Ruby object,
while `#to_i`, `#to_bv` and so on build a *new Z3 expression* of another sort -
`string_expr.to_i` is the symbolic `str.to_int`, not a Ruby Integer.

## Booleans

```ruby
~a  !a                   # negation, both spellings
a & b   a | b   a ^ b    # and, or, xor - use these, not && ||
a.implies(b)   a.iff(b)
a.ite(b, c)              # if a then b else c
Z3.And(a, b, c)   Z3.Or(...)   Z3.Xor(...)   Z3.Implies(a, b)   Z3.IfThenElse(a, b, c)
Z3::BoolSort.new.True    # and .False
bool_expr.to_b           # aliased as #value - true/false for a literal
```

Cardinality constraints are solved natively rather than unfolded into arithmetic. A
list bounds how many of the Bools are true; an `expr => weight` Hash bounds the total
weight of the true ones, which is the knapsack shape:

```ruby
Z3.AtMost([a, b, c], 2)
Z3.AtLeast([a, b, c], 2)
Z3.Exactly([a, b, c], 2)
Z3.AtMost({a => 3, b => 2, c => 5}, 7)
```

Weights are Ruby Integers and may be negative or zero, and so may the bound in the
weighted form. All weights being 1 builds the very same term the list form builds.

## Integers and Reals

Shared by both (`Z3::ArithExpr`):

```ruby
a + b   a - b   a * b   a / b   a ** b   -a
a > b   a >= b   a <= b   a < b
a.abs   a.zero?   a.nonzero?   a.positive?   a.negative?
```

`Z3::ArithExpr.Div(a, b)` and `.Power(a, b)` are the same operations spelled as
constructors. Integer division follows SMT-LIB rather than Ruby: `-7 / -2` is `4` here
and `3` in Ruby, because Z3 rounds towards making the remainder non-negative. With a
positive divisor the two agree.

Ints only:

```ruby
a.mod(b)   a % b        # SMT-LIB mod, remainder always non-negative
a.rem(b)                # SMT-LIB rem, sign follows the dividend
a.divisible_by?(3)
a.to_bv(8)              # the low 8 bits
a.to_i                  # aliased as #value
```

Reals only. Z3's Reals include the algebraic numbers, so there's no `#value` - √2 has
no exact Ruby equivalent:

```ruby
r.to_r                  # exact, raises on an irrational
r.to_f                  # approximate, and says so by being a Float
r.algebraic?
r.lower_bound(20)   r.upper_bound(20)   # rational bounds, to that many bits
r.floor   r.integer?
```

A Real literal comes from an Integer, a Rational or a finite Float -
`RealSort.new.from_const(Rational(1, 3))`.

## Bitvectors

`Z3.Bitvec("b", 8)` or `Z3::BitvecSort.new(8).var("b")`. A bitvector carries no sign
of its own, so anything where signedness matters comes in three spellings: a default,
a `signed_` one and an `unsigned_` one.

```ruby
~b   -b   b & c   b | c   b ^ c
b.nand(c)   b.nor(c)   b.xnor(c)
b + c   b - c   b * c   b / c   b % c
b.signed_div(c)   b.unsigned_div(c)
b.signed_mod(c)   b.signed_rem(c)   b.unsigned_rem(c)
b << c   b >> c                       # signed shifts by default
b.signed_lshift(c)   b.unsigned_lshift(c)
b.signed_rshift(c)   b.unsigned_rshift(c)
b.rotate_left(3)   b.rotate_right(3)
b.extract(hi, lo)   b.bit(i)   b.concat(c)   b.repeat(3)
b.zero_ext(8)   b.sign_ext(8)
b.redand   b.redor   b.all_bits_set?   b.any_bits_set?
b > c   b >= c   b <= c   b < c       # signed by default
b.signed_gt(c) ... b.unsigned_le(c)
b.zero?   b.nonzero?   b.positive?   b.negative?   b.abs
b.to_i   b.signed_to_i   b.unsigned_to_i     # new Z3 expressions, of Int sort
b.signed_value   b.unsigned_value            # Ruby Integers - #value is signed
```

Overflow and underflow predicates, for checking that an operation doesn't wrap. Each
comes in the same three spellings: `add_no_overflow?`, `add_no_underflow?`,
`sub_no_overflow?`, `sub_no_underflow?`, `mul_no_overflow?`, `mul_no_underflow?`,
`div_no_overflow?`, `neg_no_overflow?`.

Every operator also exists as a constructor on the class - `Z3::BitvecExpr.SignedDiv(a, b)`,
`.UnsignedLt(a, b)`, `.SignedAddNoOverflow(a, b)` and so on - for the cases where the
operator spelling isn't available or isn't clear.

## Floats and rounding modes

Real IEEE 754, not Reals. Sorts come from a width or from exponent and significand bits:

```ruby
Z3::FloatSort.new(:double)     # also :half, :single, :quadruple, or 16/32/64/128
Z3::FloatSort.new(11, 53)      # ebits, sbits - #ebits and #sbits read them back
```

Every arithmetic operation takes an explicit rounding mode, because IEEE says it has to:

```ruby
mode = Z3::RoundingModeSort.new.nearest_ties_even
# also nearest_ties_away, towards_zero, towards_negative, towards_positive
x.add(y, mode)   x.sub(y, mode)   x.mul(y, mode)   x.div(y, mode)
x.sqrt(mode)   x.round_to_integral(mode)   x.fused_multiply_add(y, z, mode)
x.rem(y)   x.abs   -x   x.min(y)   x.max(y)
x == y   x != y   x < y   x <= y   x > y   x >= y
x.nan?   x.infinite?   x.zero?   x.nonzero?   x.normal?   x.subnormal?
x.positive?   x.negative?
```

Building floats, and taking them apart:

```ruby
sort.from_const(1.5)                 # from a Ruby Float, or an Integer a Float can hold
sort.nan   sort.positive_infinity   sort.negative_infinity
sort.positive_zero   sort.negative_zero
sort.from_ieee_bv(bv)                # reinterpret the bits
sort.from_components(sign, exponent, significand)
sort.from_float(other, mode)   sort.from_real(r, mode)
sort.from_signed_bv(bv, mode)   sort.from_unsigned_bv(bv, mode)
sort.from_significand_and_exponent(significand, exponent, mode)

x.to_real   x.to_ieee_bv   x.to_signed_bv(32, mode)   x.to_unsigned_bv(32, mode)
x.sign_bv   x.exponent_bv(biased)   x.significand_bv
x.exponent_string(biased)   x.significand_string
x.value                              # a Ruby Float
```

A Ruby Float *is* an IEEE double, so `#value` converts every `Float(11, 53)` or
narrower literal exactly - NaN, the infinities and the two zeroes included. A wider
sort raises rather than being a `#value` that works only for small enough values.

## Strings and Chars

`Z3.String("s")`, or `Z3::StringSort.new`. The Ruby side reads like Ruby's String:
`#include?` rather than `contains`, `#sub` / `#gsub` rather than `replace` /
`replace_all`, the receiver in front of `#start_with?`, and negative indices counted
from the end.

```ruby
s.length   s.size   s.empty?
s + t                              # concatenation, also String#+ with an expr on the right
s * 3                              # repetition, Ruby-side, so the count is a Ruby Integer
s[i]   s[i, len]   s[range]        # str.at and str.substr
s.include?(t)   s.start_with?(a, b)   s.end_with?(a, b)
s.index(t, offset)   s.rindex(t)
s.sub(pattern, replacement)   s.gsub(pattern, replacement)
s.matches?(re)                     # whole-sequence match, see below
s < t   s <= t   s > t   s >= t    # Z3's string order
s.to_i   s.to_code                 # symbolic str.to_int and str.to_code
s.value                            # the Ruby String, for a literal
```

Where Ruby would answer `nil` these return whatever Z3 returns, because every one of
them is a subexpression and has to denote a String. `StringSort` also builds from
other sorts: `from_int`, `from_code`, `from_signed_bv`, `from_unsigned_bv`.

A Char is a single character of Z3's 18-bit alphabet:

```ruby
c = Z3::CharSort.new.from_const("a")
Z3::CharSort.new.from_bv(bv)
c.to_i   c.to_bv   c.digit?
c < d   c <= d   c > d   c >= d
```

## Sequences

`Z3::SeqSort.new(element_sort)`. A Seq reads like a Ruby Array, and where Ruby and
SMT-LIB disagree Ruby wins - `#include?` and `#index` take an *element*, and a bare
element is wrapped into a one element sequence, while a Ruby Array or a Seq of the
same sort is taken as the subsequence it already is.

```ruby
xs.length   xs.size   xs.empty?
xs + ys   xs * 3
xs[i]   xs[i, len]   xs.at(i)   xs.first(n)   xs.last(n)
xs.include?(3)   xs.start_with?(...)   xs.end_with?(...)
xs.index(3, offset)   xs.rindex(3)
xs.sub(pattern, replacement)   xs.gsub(pattern, replacement)
xs.matches?(re)
xs.value                          # a Ruby Array
Z3::SeqExpr.Unit(3)   Z3::SeqExpr.Concat(xs, ys)
```

Both Seq and String map and fold with a block. The block gets Z3 expressions and
returns one, so the result is a term rather than an answer - the interesting direction
is backwards, asking the solver for a sequence with the property you want:

```ruby
xs.map { |x| x * 2 }                              # Seq(Int) -> Seq(Int)
xs.map { |x| x > 1 }                              # ...and to Seq(Bool)
xs.inject(0) { |acc, x| acc + x }                 # Int
xs.map_with_index { |i, x| x * 10 + i }           # index first, Z3's order
xs.inject_with_index(0) { |i, acc, x| acc + x * i }

solver.assert xs.length == 3
solver.assert(xs.inject(0) { |acc, x| acc + x } == 10)
```

`#reduce` is `#inject`, as in Ruby, and `#mapi` / `#fold_left` / `#fold_lefti` are
aliases under Z3's own names. `map_with_index` and `inject_with_index` take `from:` to
start the index somewhere other than 0, which Ruby has no spelling for. Instead of a
block you can pass a function: `#map` takes a `Z3.Lambda`, and the other three take a
`Z3::SeqFunction`, which is what a lambda of two or three arguments has to be until
multi-dimensional array sorts exist.

A String is a `Seq(Char)` so it maps and folds too, but **Z3 will not evaluate a map
or fold over a String**. The constraint semantics are right, so asserting one is fine,
but nothing reduces the term - a model hands the unevaluated term back. Over a
`Seq(Int)` it evaluates cleanly.

## Regular expressions

`Z3::Re` is `Z3::ReExpr`, and a regex is over some sequence sort - `Re(String)` by
default, `Re(Seq(Int))` for sequences of Ints. These are deliberately not Ruby
Regexps and nothing converts between the two: Z3's denote regular languages, match the
whole sequence, and are closed under intersection and complement.

```ruby
Z3::Re.Of("cat")                  # the regex matching exactly that one value
Z3::Re.Of([1, 2], seq_sort)       # a Ruby Array needs its sort spelled out
Z3::Re.Range("a", "z")
Z3::Re.Empty   Z3::Re.Full   Z3::Re.AllChar     # each takes a seq sort, String by default
re.star   re.plus   re.option
re + other   re | other   re & other   re - other   ~re
re * 3   re * (1..3)              # Power and Loop
Z3::Re.Concat(a, b)   .Union(...)   .Intersect(...)   .Diff(a, b)   .Complement(re)
Z3::Re.Loop(re, 1, 3)
s.matches?(re)                    # or re.matches?(s)
```

Anywhere a regex is expected, a Ruby String, a Ruby Array, a StringExpr or a SeqExpr
means "the regex matching exactly this", which is what makes `Z3::Re.Union("cat", "dog")`
work. `#matches?` is the one place that doesn't happen, because Ruby's unanchored
reading and Z3's whole-sequence one differ - `s.matches?(Z3::Re.Full + re + Z3::Re.Full)`
is what Ruby's `=~` would mean.

`==` on two regexes is decided as *language equivalence*, not sameness of terms, so
`solver.prove! (a + b).star + a == a + (b + a).star` comes back proven.

## Arrays and Sets

An Array is a total map from one sort to another:

```ruby
sort = Z3::ArraySort.new(Z3::IntSort.new, Z3::IntSort.new)
a = sort.var("a")
a[3]                     # select
a.store(3, 7)            # a new array, not a mutation
a.default                # the value for every key not written
sort.Const(0)            # the array which is 0 everywhere
a.value                  # a Ruby Hash, with Hash's default holding #default
```

`ArraySort.new(x, BoolSort.new)` gives a `Z3::SetSort` instead, because that's what
Z3 makes of it: a set is a characteristic function, so it has no cardinality and is
just as happy holding everything-except-5 as it is 3 and 5.

```ruby
sort = Z3::SetSort.new(Z3::IntSort.new)
s = sort.var("s")
s.include?(3)   s.add(3)   s.delete(3)
s.union(t)   s.intersection(t)   s.difference(t)   s.complement
s.is_subset_of(t)   s.is_superset_of(t)
sort.Empty   sort.Full
s.value                  # a Ruby Set - raises for a co-finite set, which Ruby can't hold
Z3::SetExpr.Union(...)   .Intersection(...)   .Difference(a, b)   .Subset(a, b)
```

## Finite sets

New in Z3 5.0, and a set in the sense Ruby's `Set` is one. A Ruby `Set` is a value of
it, and so is an `Array`, which is the other way of writing the same thing:

```ruby
sort = Z3::FiniteSetSort.new(Z3::IntSort.new)
s = sort.var("s")
solver.assert s.include?(3)
solver.assert s.subset?(Set[1, 2, 3])
solver.assert s != Set[3]
solver.model[s].value               # => #<Set: {1, 3}>

s == Set[1, 2, 3]                   # and Set[1, 2, 3] == s, and [1, 2, 3]
```

It reads like Ruby's Set throughout - `#include?`, `#size`, `#empty?`, `#add`,
`#delete`, `#subset?`, `#proper_subset?`, `#superset?`, `#disjoint?`, `#intersect?`,
`|`, `&`, `-`, `^`, `<=`, `<`, `>=`, `>` - except that nothing mutates, so `#add`
gives back a new set the way `#union` does. `sort.Empty`, `sort.Singleton(x)` and
`sort.Range(1, 3)` (or `sort.Range(1..3)`, whose ends may be symbolic) build values;
a Ruby Range is deliberately *not* a set value, because `Set[1, 2, 3] != (1..3)` in
Ruby either.

This is the sort you usually want when you want a set. `Z3::SetSort` above is the
older `Array(X, Bool)` one, which has no cardinality.

Z3's own side of this is unfinished, and the gem works around it where it can:

* `#size` is unsound - Z3 never connects element distinctness to cardinality - and on
  Z3 5.1 a size query about a set whose elements Z3 can see aborts the process.
* `#map` refuses to build a term, because `set.map` hangs Z3 uninterruptibly.
  `#select` is fine.
* Nothing evaluates finite set operations, so `#value` walks the term in Ruby.
* On Z3 5.1 a model can contradict its own constraints - asserting `s.include?(3)`,
  `s.subset?(Set[1, 2, 3])` and `s != Set[3]` comes back `:sat` with `Set[1, 2, 3, 4]`,
  which `Model#model_eval` then says is `false`. The constraints themselves are solved
  correctly; it's the model that's wrong.

`spec/upstream_bugs_spec.rb` pins most of these down.

## Enums and Tuples

An enum is a sort whose values are a fixed list of names, and nothing else. The values
are Symbols, and they work anywhere that sort is expected:

```ruby
color = Z3::EnumSort.new("Color", %i[red green blue])
x, y = color.var("x"), color.var("y")
solver.assert x != y
solver.assert x != :red
solver.model[x].value   # => :green
```

Enums don't share a namespace, so `Color` and `Squirrel` can both have a `:red` and
the two are different values of different sorts, which Z3 won't compare.

A tuple is a record of named fields, each with a sort of its own. Fields read as
methods, and a value converts to a Hash:

```ruby
point = Z3::TupleSort.new("Point", x: Z3::IntSort.new, y: Z3::IntSort.new)
p = point.var("p")
solver.assert p.x > 0
solver.assert p == point.mk(3, 4)   # or p == [3, 4], or p == {x: 3, y: 4}
solver.model[p].value               # => {x: 3, y: 4}
```

A tuple is a sort like any other, so tuples nest, key an `Array`, and are the way to
have an uninterpreted function take or return more than one value. `p[:x]` reads a
field as well, which is how to read one named after something an expression already
answers to, like `sort` or `value` - those don't get a method of their own.

Both are declared once and share one namespace, so neither can take a name the other
has. Asking for the same one again gives back the sort you already have; asking for
the same name with different values or fields raises. The reason is Z3's: it rejects a
second enum of the same name outright, and accepts a second *tuple* while quietly
rebuilding the sort's fields from it, abandoning every term built against the first.

## Datatypes

Several named constructors, each taking any number of named fields, and any of those
fields may be the sort being declared:

```ruby
int    = Z3::IntSort.new
Option = Z3::DatatypeSort.new("Option", none: [], some: {value: int})
List   = Z3::DatatypeSort.new("List", nil: [], cons: {head: int, tail: :self})
Tree   = Z3::DatatypeSort.new("Tree", leaf: [], node: {left: :self, val: int, right: :self})
```

`:self` is the one field sort which can't be a Sort object, because the sort doesn't
exist yet while it's being declared. A field of some *other* datatype is an ordinary
Sort. Mutually recursive datatypes - a group declared at once, each mentioning the
others - aren't supported.

Constructors, recognizers and field readers are all methods:

```ruby
l = List.var("l")
l.is_cons             # or l.cons?, or l.is?(:cons)
l.head   l.tail       # Int and List, and total - nil.head is some Int Z3 won't name
List[:nil]                             # a constructor with no fields
List[cons: {head: 10, tail: :nil}]     # or List[cons: [10, :nil]]
List.mk(:cons, 10, List[:nil])         # the same value from expressions
```

Both `is_cons` and `cons?` exist for every constructor. `cons?` is skipped where Ruby
already answers to the name - `nil?` most importantly, since taking that over would
make every value of the sort look like Ruby's nil. `l[:head]` reads a field too, which
is how to read one named after something an expression already answers to.

A value is a Symbol for a constructor with no fields, the way an enum value is one,
and otherwise the constructor pointing at its fields:

```ruby
solver.model[l].value   # => {cons: {head: 10, tail: {cons: {head: 20, tail: :nil}}}}
List[solver.model[l].value]            # and straight back in
```

Two shapes of datatype are other classes' sorts, and asking for them here gives back
that class - every constructor nullary is an `EnumSort`, and a single constructor with
fields is a `TupleSort`. Z3 makes the same sort either way, so a datatype coming back
out of a model couldn't be told apart from one of those, and declaring it has to land
on the same class. The tuple's constructor is named after the sort, so
`DatatypeSort.new("Box", wrap: {v: int})` comes back with its constructor called `Box`.

Enums, tuples and datatypes share one namespace, and the same rule applies to all
three: asking for the same one again gives back the sort you already have, asking for
the same name with different constructors raises. It matters most here. Z3 accepts a
second datatype of a name it already has, hands back the sort it already had, and
attaches the new constructors to it - leaving one sort with two incompatible sets of
declarations, both of which still typecheck, and a model that can give a String-sorted
term an Int value. Z3's own SMT-LIB parser rejects the redeclaration; the C API
doesn't, so the gem does.

### Proving things about them

Datatypes are how a recursive function gets something to recurse over, and
`Z3.RecFunction` is the other half:

```ruby
len = Z3.RecFunction("len", List, int) { |len, l| Z3.IfThenElse(l.is_nil, 0, 1 + len[l.tail]) }
```

What Z3 will *not* do is prove a theorem about one. `Z3.ForAll([l], len[l] >= 0)`
doesn't come back at all - `:unknown` is what a `timeout` on the solver turns it into,
and that's the best answer available for any statement about every list. Setting
`smt.induction` doesn't rescue it, and neither does bounding the list's length: the
unfolding diverges as soon as the shape is symbolic.

What Z3 will do is discharge one case of an induction, in milliseconds. So write the
induction out and let it do the work inside each case, where a single unfolding
reduces the goal into the hypotheses:

```ruby
solver.push                                    # base case
solver.assert ~(len[List[:nil]] >= 0)
solver.check                                   # => :unsat
solver.pop

solver.push                                    # step case
solver.assert len[l] >= 0                      # the induction hypothesis
solver.assert ~(len[List.mk(:cons, x, l)] >= 0)
solver.check                                   # => :unsat
solver.pop
```

Lemmas have to be supplied by hand, as quantified assumptions, and each is proved by
the same pattern one step earlier. That's a sharp line rather than a soft one: the
step case of a theorem that needs a lemma answers `:unknown` without it and `:unsat`
with it. [`examples/insertion_sort_proof`](https://github.com/taw/z3/blob/master/examples/insertion_sort_proof)
is the whole thing end to end - insertion sort proved to return a sorted list and to
be a permutation of its input, in four inductions and two lemmas.

## Uninterpreted sorts, finite domains, type variables

An uninterpreted sort is a sort with no structure at all - the solver invents as many
elements as it needs, and the model says which ones it had to invent:

```ruby
person = Z3::UninterpretedSort.new("Person")
a, b = person.var("a"), person.var("b")
solver.assert a != b
solver.model.sorts                      # [Person]
solver.model.sort_universe(person)      # [Person!val!0, Person!val!1]
```

A finite domain sort has exactly `size` values, named 0 to `size - 1`:

```ruby
d = Z3::FiniteDomainSort.new("D", 4)
d.from_const(2).value                   # 2, an out of range value raises
```

Z3's support for this sort is thin - it's mostly there for the Datalog engine - and it
is not always sound: on Z3 5.1 asserting `d != 0` can come back `:sat` with a model
saying `d = 0`. Distinctness constraints do work, but check anything else against
`Model#model_eval` before believing it.

`Z3::TypeVariableSort.new("T")` builds Z3 5.0's type variable sort and variables of
it. Nothing else in the gem consumes one - polymorphic declarations aren't wired up.

## Functions

`Z3.Function` declares an uninterpreted function - a symbol the solver decides the
meaning of. The last sort is the range and the ones before it the domain, the same
order SMT-LIB's `declare-fun` uses, and you apply it with `[]`:

```ruby
f = Z3.Function("f", Z3::IntSort.new, Z3::IntSort.new)
solver.assert f[f[x]] == x
solver.assert f[x] != x
```

`Z3.FreshFunction(prefix, *sorts)` is the same with a name Z3 picks, for helpers which
mustn't collide with anything you've named.

`Z3.RecFunction` declares a function which *is* its body, SMT-LIB's `define-fun-rec`,
which is what you want when a quantified axiom over `Z3.Function` would only say "f is
characterised by this". Declaring and defining are two steps so that the body can
mention the function it defines - the block form does both, and gets the function as
its first argument:

```ruby
int, bool = Z3::IntSort.new, Z3::BoolSort.new

fact = Z3.RecFunction("fact", int, int) { |fact, n| Z3.IfThenElse(n <= 0, 1, n * fact[n - 1]) }
solver.assert fact[5] == x
solver.model[x].to_i   # => 120

even = Z3.RecFunction("even", int, bool)      # two mutually recursive functions
odd  = Z3.RecFunction("odd", int, bool)       # need the declarations first
even.define { |n| Z3.IfThenElse(n == 0, true, odd[n - 1]) }
odd.define { |n| Z3.IfThenElse(n == 0, false, even[n - 1]) }

solver.assert even[10]                        # sat, and even[7] is unsat
```

A declaration you never `#define` is not an error and doesn't announce itself - it
just behaves as an uninterpreted function, so `even[7]` would come back `:sat` on the
strength of the solver being free to decide what `even` means.

Two things more to know. Z3 doesn't check that the recursion terminates, and one it
can't finish unfolding comes back as `:unknown` rather than an error. And a definition
belongs to the context rather than to any solver, exactly as it would in an SMT-LIB
script - so it is permanent, and every solver created afterwards carries it, which can
change the model an unrelated query gets back.

A declaration itself answers `#name`, `#arity`, `#domain(i)`, `#range`, `#recursive?`,
`#[]` / `#call`, and `#define`.

## Quantifiers and lambdas

```ruby
Z3.ForAll(x, f[x] > 0)
Z3.Exists([x, y], f[x] == y)
Z3.Lambda(x, x * 2)          # an anonymous function, which comes back as an Array
```

`bound` is the variable, or variables, the quantifier binds - the very same ones the
body was built out of, which Z3 rebinds inside it. Everywhere else they go on meaning
what they always did.

A quantified problem is a different kind of problem: `Solver#check` can return
`:unknown`, and on some inputs it doesn't return at all. Set `timeout` or `rlimit` on
the solver when that matters:

```ruby
solver = Z3::Solver.new(timeout: 2000)
```

A lambda is an Array value, so `Z3.Lambda(x, x * 2)[3]` is 6, and it's what
`SeqExpr#map` takes instead of a block.

## Solver

```ruby
Z3::Solver.new(params = {})       # inspects the assertions and assembles a tactic
Z3::Solver.simple(params = {})    # just the incremental SMT core
Z3::Solver.for_logic("QF_LIA")    # specialised, often much faster, raises outside the logic
Z3::Solver.from_tactic(tactic)    # every #check runs the tactic
solver.with_simplifier(simplifier) # a *new* solver with preprocessing attached
solver.simple?
```

The core loop:

```ruby
solver.assert(x > 0)
solver.push   solver.pop(n = 1)   solver.reset   solver.num_scopes
solver.check                      # :sat, :unsat, :unknown
solver.satisfiable?   solver.unsatisfiable?
solver.model
solver.assertions
solver.reason_unknown
solver.to_s   solver.to_dimacs(include_names = true)
solver.prove!(claim)              # asserts the negation and prints the verdict
```

`#check`, `#satisfiable?` and `#unsatisfiable?` take assumptions - Bool exprs taken as
true for that one check and nothing after it, leaving no trace on the solver. They're
also what `#unsat_core` blames:

```ruby
solver.check(a, ~b)
solver.unsat_core
```

The other way to get an unsat core is to name assertions as you make them. Only tracked
assertions can ever be blamed:

```ruby
solver.assert_and_track(x > 10, Z3.Bool("t1"))
solver.assert_and_track(x < 5,  Z3.Bool("t2"))
solver.check        # :unsat
solver.unsat_core   # [t1, t2]
```

Inspecting and steering the search:

```ruby
solver.consequences([x, y], assumptions)  # everything about those variables which follows
solver.cube(variables = [], backtrack_level = 0)  # one case split at a time
solver.units   solver.non_units           # what's been boiled down to a literal, and what hasn't
solver.trail                              # assigned literals, Solver.simple only
solver.set_initial_value(x, 42)           # a warm start hint, Solver.simple only
solver.interrupt                          # from another thread or a signal handler
solver.statistics                         # a Hash
solver.help                               # what its parameters do
solver.param_descrs   solver.set_params(timeout: 1000)
```

SMT-LIB2 goes in directly. Anything it declares lands in the shared context, so
`(declare-const a Int)` is the same variable as `Z3.Int("a")` - but the parser starts
with an empty symbol table each time, so every string has to declare what it uses:

```ruby
solver.from_string("(declare-const a Int)(assert (> a 10))")
solver.from_file("problem.smt2")
```

## Model

```ruby
model[x]                  # what the model says x is
model.model_eval(term, model_completion = false)
model.to_s   model.inspect
model.each { |decl, value| }     # constants and functions alike
model.each_const   model.each_func
model.consts   model.num_consts
model.funcs    model.num_funcs
model.func_interp(f)
model.has_interp?(x)      # whether the model says anything about x at all
model.sorts   model.sort_universe(sort)
!model                    # the negation - assert it to ask for a different model
```

An uninterpreted function comes back as a Hash from argument lists to values, with
Ruby's Hash default holding Z3's `else` branch - the answer for every argument the
solver never had to pin down. Z3 picks one of the values as that fallback, so the
entries are only the exceptions to it:

```ruby
# after asserting f[1] == 10 and f[2] == 20
interp = model.func_interp(f)   # {[2] => 20}
interp.default                  # 10 - which is also the answer for f[1] and f[999]
model.to_s                      # Z3::Model<f={(2) => 20, else => 10}>
```

Recursive definitions are left out of `#funcs`: Z3 puts every one made in the context
into every model whether the query mentioned it or not, and it hands back the
definition rather than anything the model decided.

`!model` gives the constraint "not this exact model", which is how to enumerate
solutions:

```ruby
while solver.satisfiable?
  p solver.model.to_s
  solver.assert !solver.model
end
```

Models don't have to come from a solver. `Model.new` takes the same shape `#each`
yields - variables and FuncDecls to values, a function's entries keyed by argument
list with `default:` for the `else` branch:

```ruby
model = Z3::Model.new(x => 3, y => 4, f => {[1] => 10, default: 0})
model.model_eval(x*x + y*y == 25, true)   # true - no solver involved anywhere
Z3::Model.new(solver.model.to_h)          # a model read out goes back in
```

That makes `Model` an evaluator for any expression under any assignment, which is how
to check a candidate answer without asking Z3 to search for one, and it's what feeds
`Goal#convert_model` a model of a subgoal you solved some other way. A model built
here is only what it was told - nothing checks it against any assertions, and it can
say something false. Two things it can't be told: what elements an uninterpreted sort
has (Z3 has no writer for those, so `#sorts` stays empty), and what a recursive
definition does (that belongs to the context, and `Model.new` refuses it).

## Optimize

`Z3::Optimize` is a solver with objectives. Everything `Solver` does with assertions
it does too - `#assert`, `#assert_and_track`, `#push`, `#pop`, `#check`,
`#satisfiable?`, `#unsatisfiable?`, `#model`, `#assertions`, `#unsat_core`,
`#statistics`, `#help`, `#param_descrs`, `#set_params`, `#reason_unknown`, `#to_s`,
`#prove!` - plus:

```ruby
opt.maximize(x * 2 + y)
opt.minimize(cost)
opt.assert_soft(x > 0, "3")           # weight is a String, and defaults to "1"
```

Soft constraints are the ones Z3 is allowed to break, paying their weight when it
does, so `assert_soft` plus `check` is MaxSAT. The weight is a String because that's
Z3's own interface to it. `#assert_soft` takes a third argument for the group a soft
constraint belongs to, but it wants a raw Z3 symbol and nothing builds one, so leave
it alone.

```ruby
opt = Z3::Optimize.new
opt.assert x >= 0
opt.assert y >= 0
opt.assert x + y <= 10
opt.maximize(x * 2 + y)
opt.satisfiable?     # true
opt.model.to_s       # Z3::Model<x=10, y=0>
```

Z3's objective value readers aren't bound, so read the maximised term out of the model
rather than from the return value of `#maximize`.

SMT-LIB2 goes in the same way it does for a solver, except that this parser knows the
optimization commands too:

```ruby
opt.from_string("(declare-const a Int)(assert (> a 10))(assert-soft (= a 20))(minimize a)")
opt.from_file("problem.smt2")
```

`opt.set_initial_value(b, true)` is the same warm start hint `Solver.simple` takes,
but Bool and Bitvec only. Z3's optimizer drops an Int hint in preprocessing, and hands
a Real one back scaled - with any objective in play that means a model which fails its
own assertions - so those two raise here instead of being passed through.
`Solver.simple` takes arithmetic warm starts correctly, and
`spec/upstream_bugs_spec.rb` reproduces both bugs.

## Tactics, probes, goals, simplifiers

A goal is a set of formulas to work on, a tactic turns one goal into the subgoals which
replace it, and a probe measures a goal so a tactic can branch on it.

```ruby
goal = Z3::Goal.new(models = false, unsat_cores = false, proofs = false)
goal.assert(x > 0)
goal.size   goal.depth   goal.num_exprs   goal.precision
goal.inconsistent?   goal.decided_sat?   goal.decided_unsat?
goal.formula(0)   goal.each { |f| }      # the formulas, which is how a goal gets into a Solver
goal.convert_model(model)                # a subgoal's model, back in terms of the original
goal.to_s   goal.to_dimacs   goal.reset
```

```ruby
Z3::Tactic.names   Z3::Tactic.description("simplify")
t = Z3::Tactic.named("simplify")
t.apply(goal, params = {})               # an ApplyResult - the subgoals
t.and_then(other)   t.or_else(other)   t.parallel_and_then(other)
t.repeat(n)   t.try_for(ms)   t.using_params(params)
Z3::Tactic.par_or(a, b)   .when(probe, t)   .cond(probe, t1, t2)
Z3::Tactic.fail   .fail_if(probe)   .fail_if_not_decided   .skip
t.help   t.param_descrs
```

An `ApplyResult` is Enumerable over its subgoals, with `#size` and `#[]`. The original
goal is satisfiable exactly when one of the subgoals is, so no subgoals at all means
the tactic decided it's unsatisfiable, and a single `decided_sat?` subgoal means it
decided the other way.

```ruby
Z3::Probe.names   Z3::Probe.description("num-consts")
p = Z3::Probe.named("num-consts")
p.apply(goal)                            # a Float
p == 3   p > 3   p >= 3   p < 3   p <= 3 # comparisons give Probes, not answers
p & q   p | q   ~p   !p
Z3::Probe.const(3)
```

A simplifier is incremental preprocessing for a solver. Unlike a tactic there's
nothing to apply it to - attaching it is the only way to use one - and `#and_then` is
its only combinator:

```ruby
Z3::Simplifier.names   Z3::Simplifier.description("solve-eqs")
solver = Z3::Solver.new.with_simplifier(Z3::Simplifier.named("solve-eqs"))
```

`Simplifier.named` refuses the ones Z3 gets wrong on the running version -
`Simplifier.unsound` is that list, and `spec/upstream_bugs_spec.rb` reproduces each bug.

## Parameters and statistics

`Solver`, `Optimize`, `Tactic`, `Simplifier` and `AST#simplify` all take a parameters
Hash, and all describe what they accept:

```ruby
Z3::Solver.new(timeout: 1000, unsat_core: true)
solver.set_params(random_seed: 42)       # parameters accumulate
descrs = solver.param_descrs
descrs.names   descrs.size   descrs.kind(:timeout)   descrs.include?(:timeout)
descrs.documentation(:timeout)
solver.help                              # the same thing as one block of text
```

Values are checked against the descriptions before Z3 sees them, because Z3's answer
to a bad name is a warning on stderr rather than an error. `Z3::Params.new(hash, descrs)`
builds one explicitly; passing a `Params` instead of a Hash skips the checking.

`#statistics` on a solver or an optimize gives a Ruby Hash of Z3's counters.

Global parameters are the ones the `z3` binary takes on its command line. Names are
case insensitive and everything is a String in both directions:

```ruby
Z3.set_param("pp.decimal", "true")
Z3.get_param("pp.decimal")
Z3.reset_params
Z3.param_descrs            # the unqualified ones
Z3.simplify_param_descrs   # what AST#simplify takes
Z3.simplify_help
```

`proof` is the one global parameter that can't work this way: Z3 reads it while
creating the context, so `set_param` warns and does nothing. `Z3.configure` below is
where it belongs.

### Context parameters

A handful of parameters are read while Z3 builds the context, and can't be set any
other way. `Z3.configure` takes them as a Hash, and has to run before anything else
touches Z3 - the context is created lazily, on the first call that needs it, and
configuring after that raises rather than quietly doing nothing:

```ruby
require "z3"
Z3.configure(proof: true, timeout: 5000)   # before any other Z3 call

Z3.configuration      # {"proof" => true, "timeout" => 5000}
```

Calling it more than once merges, so a later call overrides an earlier one, and names
arrive as Strings either way - `proof:` and `"proof" =>` are the same parameter.
Values reach Z3 as Strings too, so `true`, `"true"` and `1` all end up as something
Z3 parses itself.

The eleven parameters, which is all of them, are `proof`, `debug_ref_count`, `trace`,
`trace_file_name`, `timeout`, `well_sorted_check`, `auto_config`, `model`,
`model_validate`, `unsat_core` and `encoding`. `Z3::CONTEXT_PARAMS` is that list;
anything else raises, because `Z3_set_param_value` ignores a name it doesn't know
without saying a word.

`proof: true` is the reason this exists. Z3 keeps no proof at all unless the context
was built for it - `Z3_solver_get_proof` answers "there is no current proof" - and
there's no `Solver#proof` yet, so reaching the proof term itself still means going
through `LowLevel`.

## Ruby integration and its limits

`==` on an expression builds a `Z3::BoolExpr` rather than answering `true` or `false`,
and every `BoolExpr` is truthy:

```ruby
a = Z3.Int("a")
b = Z3.Int("b")
a == b     # => Bool<a = b>, not false
```

That's the whole point of the gem, and Ruby's core classes are patched so the
expression can be on either side - `1 == a` builds the same equation `a == 1` does, and
so do `true`, `"a"`, `:red`, `[1, 2]` and `{x: 1, y: 2}` against the sorts which can
hold them. `Integer`, `Float` and `Rational` get the ordering operators too, so
`1 < a` works; `String` gets `+` and the comparisons. The cost is that anything asking
`==` a question and expecting a Ruby answer gets an expression instead, which reads as
"yes".

### Containers which work

Hash and Set look their keys up with `#hash` and `#eql?`, not with `==`, and
expressions answer those properly. Z3 interns its ASTs, so two expressions are `eql?`
exactly when they're the same term - and being built separately doesn't make them
different:

```ruby
{a => 1, b => 2}[b]      # => 2
Set[a, b].include?(c)    # => false
[a, b].uniq              # => [a, b]
[a, a].uniq              # => [a]
(a + 1).eql?(a + 1)      # => true
(a + 1).eql?(1 + a)      # => false - a different term, not a different value
```

So Hash reading and writing, `#key?`, Set membership, and the Array operations built
on hashing - `#uniq`, `#-`, `#&`, `#|`, `#tally`, `#group_by` - all behave as you'd
expect. `#eql?` is also how you ask whether two expressions are the same term, which is
the question `==` would have answered in a library that wasn't this one.

This is where the Ruby gem differs from [crystal-z3](https://github.com/taw/crystal-z3),
where Hash and Set have the problem too - Crystal has no `eql?`, so `==` has to do both
jobs at once.

### Containers which don't

Anything which searches with `==` stops at the first thing it looks at, and anything
which counts or deletes by `==` matches everything:

```ruby
[a] == [b]           # => true
[a].include?(b)      # => true, for any b
[a, b].index(b)      # => 0
[a, b].count(b)      # => 2
[a, b].delete(b)     # removes both
{x: a} == {x: b}     # => true - Hash#== compares its values with ==
{1 => a}.value?(b)   # => true
```

`case`/`when` goes the same way, because `Object#===` is `==` unless a class says
otherwise, so the first branch mentioning an expression always wins. So does ordering:
`Object#<=>` answers `0` whenever `==` is truthy, which makes every expression compare
equal to every other, and `#sort`, `#min` and `#max` quietly hand back the order they
were given.

Building these collections is fine. It's only reading from them which lies, and
`#eql?` reads correctly - `[a, b].index{|x| x.eql?(b)}` is `1`.

The same applies with the Ruby value on the left, since that's the half the patched
core classes make work: `[1].include?(a)` is `true`. Hashing is unaffected there too,
so `Set[1].include?(a)` is `false` and `{1 => :x}[a]` is `nil`.

### nil

`nil` isn't a Z3 value, and it's the one case left where the two sides disagree:

```ruby
a == nil    # raises Z3::Exception
nil == a    # => false
```

`NilClass` is deliberately not patched. Making it match would mean raising, and Ruby
asks `nil == x` on its own, in places where an exception would stop the whole call
rather than the element - `[nil, 1].include?(a)` asks it of the first element before
going on to the second. Plain `Object`s are left alone for the same reason.

Ruby's implicit conversion methods - `to_str`, `to_int`, `to_ary`, `to_hash`,
`to_proc` - are deliberately **not** defined on expressions. Ruby calls those on its
own whenever it wants that exact type, and no Z3 expression can promise to be one.

## Global settings and internals

```ruby
Z3.version                        # "5.1.0.0"
Z3.version_at_least?(5, 0)
Z3.estimated_alloc_size           # Z3's own estimate, process wide
Z3.enable_concurrent_dec_ref      # makes refcount decrements thread safe
Z3::Context.created?              # whether anything has needed the context yet
```

There is exactly one `Z3::Context`, created on the first call that needs one, and no
public method takes one. Requiring the gem doesn't create it - that's what leaves room
for [`Z3.configure`](#context-parameters). That's a deliberate limitation: supporting several would mean
a context parameter on every sort, expr, solver and model, and a context isn't safe to
use from more than one thread anyway.

Memory leaks. The context is built with `Z3_mk_context` rather than `Z3_mk_context_rc`,
so ASTs live as long as it does and nothing Z3 hash-conses is ever released - dropping
every reference and running Ruby's GC doesn't move `Z3.estimated_alloc_size`. Only the
refcounted objects (`Solver`, `Model`, `Tactic` and the rest) are released, from
ObjectSpace finalizers. If you run threads, call `Z3.enable_concurrent_dec_ref` before
starting them: a finalizer runs on whichever thread triggered the collection, and Z3's
decrements aren't thread safe by default.

`Z3::VeryLowLevel` and `Z3::LowLevel` are the FFI interfaces, for internal use. Don't
call them, and don't call any method starting with `_` - doing so is likely to
segfault rather than raise. `api/gen_api` regenerates the FFI bindings from Z3's
`z3_api.h`, which is how the gem keeps up with upstream.
