# Z3用のRubyバインディング

<!-- hy-mt2-i18n:start -->
[English](./README.md) | [中文](./README_zh-CN.md) | **日本語** | [Español](./README_es.md)
<!-- hy-mt2-i18n:end -->


これは[Z3](https://github.com/Z3Prover/z3)用のRubyインターフェースです。

推奨される[Z3](https://github.com/Z3Prover/z3)のバージョンは4.16以降です。まずはそれをインストールしておいてください（MacOSの場合は例えば`brew install z3`など）。

```sh
gem install z3
```

[APIドキュメントはこちらです](https://taw.github.io/z3/)。

## 基本使い方

変数は `Z3.Bool`、`Z3.Int`、`Z3.Real`、`Z3.Bitvec` を使って初期化されます。

`Z3::Solver`および`Z3::Optimize`を使って制約を課し、問題を解きます。

```ruby
require 'z3'

# Z3変数の作成
a, b = Z3.Int('a'), Z3.Int('b')

# 式を使って制約を追加
solver = Z3::Solver.new
solver.assert(a > 1)
solver.assert(b > 0)
solver.assert(a + b == 3)

# 満足可能性のチェックとモデルの取得
if solver.satisfiable?
  model = solver.model

  # Z3モデルをRuby型に変換
  hash = model.to_h do |zvar, zvalue|
    [zvar.to_s, zvalue.value]
  end

  p hash
  # {"a" => 2, "b" => 1}
end
```

## インターフェース

公開されているインターフェースとは、`Z3`モジュール内のさまざまなメソッド、およびそのモジュールによって作成されたオブジェクト上のメソッドのことです。

[`examples/`](https://github.com/taw/z3/blob/master/examples) ディレクトリが、始めるのに最適な場所でしょう。

Z3式を構築する際にはほとんどのRuby演算子を使用できますが、論理演算子については`|| &&`の代わりに`| &`を使う必要があります。残念ながらこれらの演算子の優先順位は正しくないため、追加の括弧を使用する必要があります。

Z3式からRubyオブジェクトを取得するには`#value`を使用します。これはZ3がリテラルに還元できるあらゆる式で動作し、特にモデルから得られる式で最も有用です。それ以外の場合は例外が発生します。

```ruby
Z3.Const(42).value                          # 42
Z3.Const(true).value                        # true
Z3::StringSort.new.from_const("hi").value   # "hi"
Z3.Int("a").value                           # エラーが発生 – “a”はリテラルではない
```

`Bitvec`には独自の符号情報がないため、代わりに`#signed_value`と`#unsigned_value`が用意されている。同じ8ビットでも、ある読み方をすると`200`となり、別の読み方をすると`-56`となる。`Real`および`Float`には`#value`が存在しない。これは、これらのリテラルが必ずしも正確なRubyの等価値を持たないからだ。

`#value`は`#to_i`やその他の関数とは異なる点に注意してください。`#value`はZ3の環境を出てRubyオブジェクトを返しますが、`#to_i`、`#to_bv`といった関数は別の種類の*新しいZ3式*を生成します。例えば`string_expr.to_i`はRubyのIntegerではなく、記号的な`str.to_int`に相当します。`Int`の場合は両者が同じメソッドとなりますが、これはIntをIntに変換することに他の意味はないからです。

Rubyの暗黙的変換メソッドである`to_str`、`to_int`、`to_ary`、`to_hash`、`to_proc`は、意図的に式上で定義されていません。Rubyはその正確な型が必要な場合に自動的にこれらのメソッドを呼び出し、どのZ3式も特定の型であると保証することはできません。

このインターフェースは不安定な可能性があり、将来的に変更されることがあります。

`Z3::VeryLowLevel` および `Z3::LowLevel` は内部利用向けのFFIインターフェースであり、直接使用してはいけません。また、_で始まるメソッドも使用しないでください。細心の注意を払わない限り、これらを使用するとセグメンテーションエラーが発生する可能性が高いです。

`api/gen_api` にあるユーティリティが.h ファイルを順番に処理し、Ruby 用の定義を生成します。これにより、上流側で `z3_api.h` が変更された際に API が自動的に更新されます。

## ビルド

```
brew install z3
rake gem:build
bundle install
rake spec
```

### 既知の問題点

Z3はCライブラリであるため、何か異常な操作を行うとプロセスがセグフールトを起こします。Ruby APIはこうした問題を防ぎ、例外として処理するよう最善を尽くしますが、何か異常な操作を行った場合（特に `_` で始まるメソッドや `Z3::LowLevel` インターフェースのメソッドに手を出した場合）、クラッシュが発生する可能性があります。もし一見正常なコードで再現可能なクラッシュが起きた場合は、必ずバグとして報告してください。そうすれば私が対処法を考えてみます。

Z3はASTのインターニングと参照カウントを積極的に組み合わせているため、Rubyスタイルのメモリ管理とはあまり互換性がなく、メモリ漏れがかなり発生します。通常は一般的なSymbolによるメモリ漏れほど深刻ではありませんが、外部から入力を受け取る長時間実行されるプロセスではZ3の使用は避けた方が良いでしょう。

### Pythonの例

いくつかの例としてのソルバーには、https://github.com/taw/puzzle-solvers から入手可能な Python バージョンもあります。
