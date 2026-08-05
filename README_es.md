# Vinculaciones de Ruby para Z3

<!-- hy-mt2-i18n:start -->
[English](./README.md) | [中文](./README_zh-CN.md) | [日本語](./README_ja.md) | **Español**
<!-- hy-mt2-i18n:end -->


Se trata de una interfaz en Ruby para [Z3](https://github.com/Z3Prover/z3).

La versión recomendada de [Z3](https://github.com/Z3Prover/z3) es 4.16 o superior. Asegúrese de tenerla instalada primero (por ejemplo, `brew install z3` en MacOS).

```sh
gem install z3
```

[La documentación de la API está aquí](https://taw.github.io/z3/).

## Uso básico

Las variables se inicializan con `Z3.Bool`, `Z3.Int`, `Z3.Real` y `Z3.Bitvec`.

Restrinja y resuelva con `Z3::Solver` y `Z3::Optimize`.

```ruby
require 'z3'

# Crear variables de Z3
a, b = Z3.Int('a'), Z3.Int('b')

# Añadir restricciones con expresiones
solver = Z3::Solver.new
solver.assert(a > 1)
solver.assert(b > 0)
solver.assert(a + b == 3)

# Verificar si hay solución y obtener el modelo
if solver.satisfiable?
  model = solver.model

  # Convertir el modelo de Z3 a tipos de Ruby
  hash = model.to_h do |zvar, zvalue|
    [zvar.to_s, zvalue.value]
  end

  p hash
  # {"a" => 2, "b" => 1}
end
```

## Interfaz

La interfaz pública está formada por varios métodos en el módulo `Z3`, así como en los objetos que este crea.

El directorio [`examples/`](https://github.com/taw/z3/blob/master/examples) es probablemente el mejor lugar para comenzar.

Puede utilizar la mayoría de los operadores de Ruby para construir expresiones Z3, pero debe usar `| &` en lugar de `|| &&` para los operadores booleanos. Lamentablemente, estos tienen una precedencia incorrecta, por lo que será necesario emplear paréntesis adicionales.

Para obtener un objeto de Ruby a partir de una expresión de Z3, utilice `#value`. Funciona con cualquier expresión que Z3 pueda reducir a un valor literal; es más útil con aquellos obtenidos de un modelo; de lo contrario, lanza un error.

```ruby
Z3.Const(42).value                          # 42
Z3.Const(true).value                        # true
Z3::StringSort.new.from_const("hi").value   # "hi"
Z3.Int("a").value                           # lanza un error: "- 'a' no es un literal"
```

Un `Bitvec` no tiene su propio signo, por lo que en su lugar existen los métodos `#signed_value` y `#unsigned_value`: esos mismos ocho bits representan el valor `200` si se leen de una manera y `-56` si se leen de otra. `Real` y `Float` no disponen del método `#value`, ya que sus valores literales no siempre tienen un equivalente exacto en Ruby.

Tenga en cuenta que `#value` no es lo mismo que `#to_i` y otros métodos similares. `#value` sale de Z3 y le entrega un objeto Ruby, mientras que `#to_i`, `#to_bv`, etc., crean una *nueva expresión Z3* de otro tipo: `string_expr.to_i` corresponde al operador simbólico `str.to_int`, no a un entero de Ruby. En el caso de `Int`, ambos métodos son idénticos, ya que convertir un Int en otro Int no puede significar nada más.

Los métodos de conversión implícita de Ruby —`to_str`, `to_int`, `to_ary`, `to_hash`, `to_proc`— están deliberadamente **sin definirse** en las expresiones. Ruby los llama por sí mismo cada vez que necesita ese tipo específico, y ninguna expresión de Z3 puede garantizar serlo.

La interfaz es potencialmente inestable y puede cambiar en el futuro.

`Z3::VeryLowLevel` y `Z3::LowLevel` son interfaces FFI de uso interno, por lo que no se deben utilizar directamente. Tampoco se deben usar los métodos que comienzan con `_`. Hacerlo probablemente causará fallos de segmentación a menos que se tenga mucho cuidado.

Una herramienta ubicada en `api/gen_api` recorrerá un archivo.h y generará las definiciones en Ruby. Esto permitirá actualizar la API cuando el código fuente modifique `z3_api.h`.

## Compilación

```
brew install z3
rake gem:build
bundle install
rake spec
```

### Problemas conocidos

Dado que Z3 es una biblioteca en C, realizar cualquier acción inusual con ella provocará un fallo de segmentación en su proceso. La API de Ruby hace todo lo posible por evitar tales problemas y convertirlos en excepciones, pero si se realizan acciones inusuales (especialmente si se modifica algún método que comience con `_` o la interfaz `Z3::LowLevel`), es posible que ocurran caídas del programa. Si experimenta caídas reproducibles con código que parece razonable, por favor envíelo como error; intentaré encontrar una solución alternativa.

Dado que Z3 combina de forma intensiva el almacenamiento interno de árboles sintácticos y el conteo de referencias, no es muy compatible con el sistema de gestión de memoria propio de Ruby, por lo que ocurren fugas de memoria en cantidades considerables. Por lo general, no es mucho peor que las habituales fugas de memoria relacionadas con los Symbol, pero sería recomendable evitar usar Z3 en procesos que funcionen durante mucho tiempo y estén expuestos a entradas provenientes del usuario.

### Ejemplos en Python

Algunos de los solvers de ejemplo también cuentan con versiones en Python disponibles en https://github.com/taw/puzzle-solvers
