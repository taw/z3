# Z3 的 Ruby 绑定

<!-- hy-mt2-i18n:start -->
[English](./README.md) | **中文** | [日本語](./README_ja.md) | [Español](./README_es.md)
<!-- hy-mt2-i18n:end -->


这是针对 [Z3](https://github.com/Z3Prover/z3) 的 Ruby 接口。

推荐的[Z3](https://github.com/Z3Prover/z3)版本为4.16或更高。请先确保已安装该版本（例如在MacOS上可使用`brew install z3`）。

```sh
gem install z3
```

[API文档请点击此处](https://taw.github.io/z3/)。

## 基本用法

变量可通过 `Z3.Bool`、`Z3.Int`、`Z3.Real`、`Z3.Bitvec` 进行初始化。

使用 `Z3::Solver` 和 `Z3::Optimize` 进行约束设定与求解。

```ruby
require 'z3'

# 创建 Z3 变量
a, b = Z3.Int('a'), Z3.Int('b')

# 使用表达式添加约束条件
solver = Z3::Solver.new
solver.assert(a > 1)
solver.assert(b > 0)
solver.assert(a + b == 3)

# 检查是否可满足，并获取模型
if solver.satisfiable?
  model = solver.model

  # 将 Z3 模型转换为 Ruby 类型
  hash = model.to_h do |zvar, zvalue|
    [zvar.to_s, zvalue.value]
  end

  p hash
  # {"a" => 2, "b" => 1}
end
```

## 接口

其公共接口为 `Z3` 模块中的各类方法，以及由该模块创建的对象上的方法。

[`examples/`](https://github.com/taw/z3/blob/master/examples) 目录或许是最佳的入门起点。

你可以使用大多数 Ruby 运算符来构建 Z3 表达式，但布尔运算符应使用 `| &` 而非 `|| &&`。遗憾的是这两者的运算优先级设置不正确，因此你需要额外添加括号来调整顺序。

若要从 Z3 表达式中获取 Ruby 对象，可使用 `#value` 方法。该方法适用于任何能被 Z3 转换为字面值的表达式——尤其是从模型中获取的表达式——否则会抛出异常。

```ruby
Z3.Const(42).value                          # 42
Z3.Const(true).value                        # true
Z3::StringSort.new.from_const("hi").value   # "hi"
Z3.Int("a").value                           # 会抛出异常——"a"并非字面量
```

`Bitvec` 自身没有符号信息，因此它使用 `#signed_value` 和 `#unsigned_value` 来表示——相同的这8位数据，一种解读方式下是200，另一种解读方式下则是-56。`Real` 和 `Float` 类型没有 `#value` 方法，因为它们的字面量并不总存在对应的精确 Ruby 对象。

请注意，`#value` 与 `#to_i` 及其类似方法并不相同。`#value` 会脱离 Z3 环境并将结果作为 Ruby 对象返回，而 `#to_i`、`#to_bv` 等方法则会生成另一种类型的*新 Z3 表达式*——`string_expr.to_i` 实际上等同于符号层面的 `str.to_int`，而非 Ruby 的整数类型。对于 `Int` 类型而言，这两种方法是相同的，因为将 Int 转换为 Int 本就不可能有其他含义。

Ruby 的隐式转换方法——`to_str`、`to_int`、`to_ary`、`to_hash`、`to_proc`——是刻意**未**在表达式上定义的。每当 Ruby 需要特定类型时，它会自行调用这些方法，而没有任何 Z3 表达式能够保证具备该类型。

该接口可能存在不稳定性，未来可能会发生变化。

`Z3::VeryLowLevel` 和 `Z3::LowLevel` 是用于内部使用的 FFI 接口，不应直接使用。同时也不要使用任何以 `_` 开头的方法，除非格外谨慎，否则很可能会导致段错误。

位于 `api/gen_api` 的工具会遍历 `.h` 文件并生成 Ruby 定义。这样当上游代码修改 `z3_api.h` 时，API 也会随之更新。

## 构建

```
brew install z3
rake gem:build
bundle install
rake spec
```

### 已知问题

由于 Z3 是一个 C 库，对其进行任何异常操作都可能导致进程出现段错误。Ruby API 会尽力避免这类问题，并将其转化为异常，但如果你做了什么奇怪的操作（尤其是调用了以 `_` 开头的方法或 `Z3::LowLevel` 接口中的方法），程序仍有可能崩溃。如果你在看似正常的代码中遇到了可复现的崩溃问题，务必将其作为缺陷提交，我会尽力寻找解决方案。

由于 Z3 大量采用了 AST 内存驻留与引用计数相结合的方式，其与 Ruby 风格的内存管理机制兼容性较差，因此很容易出现内存泄漏问题。虽然这种情况通常不会比常见的 Symbol 内存泄漏更严重，但对于那些需要处理公共输入且会长期运行的进程而言，还是建议避免使用 Z3。

### Python 示例

部分示例求解器也有对应的 Python 版本，可在 https://github.com/taw/puzzle-solvers 获取。
