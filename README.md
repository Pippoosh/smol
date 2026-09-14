# smol

A smol programming language written in Odin.

## Features

It has:

* integers
* booleans
* variables
* arithmetic
* comparisons
* `if`
* `goto`
* integer input

It does *not* have:

* strings
* functions
* arrays
* structs
* loops
* a standard library
* common sense

Everything is an S-expression, because why not?

## Usage

Requires [Odin](https://odin-lang.org/).

```sh
odin build .
./smol examples/table.smol
```

Or without a binary:

```sh
odin run . examples/table.smol
```

Type an integer when prompted (`>`).

## Example

```smol
; Compute and print the table of a number entered by the user till 12
;
; 1. read the number
; 2. start i at 0
; 3. increment i
; 4. print x * i
; 5. loop back to 3 until i reaches 12

( let x <-> )
( let i 0 )
( let i ( + i 1 ) )
( * x i )
( if ( < i 12 ) ( goto 3 ) )
```

There are no loops, so this one is `if` plus `goto`. Expression numbers skip comments and blank lines, and they start at 1.

`let` is silent. Everything else that actually runs gets printed, which is why the table appears.

## More examples

| File | What it does |
| ---- | ------------ |
| [`examples/arithmetic.smol`](examples/arithmetic.smol) | `+` `-` `*` `/` `%` |
| [`examples/logic.smol`](examples/logic.smol) | Comparisons and `||` `&&` `!` |
| [`examples/table.smol`](examples/table.smol) | Multiplication table (input) |
| [`examples/max.smol`](examples/max.smol) | Larger of two integers |
| [`examples/factorial.smol`](examples/factorial.smol) | Factorial |
| [`examples/gcd.smol`](examples/gcd.smol) | Greatest common divisor |
| [`examples/collatz.smol`](examples/collatz.smol) | Collatz sequence |

Max of two numbers, with no `else`:

```smol
( let a <-> )
( let b <-> )
( if ( > a b ) ( goto 6 ) )
b
( goto 7 )
a
( let done true )
```

`a` is expression 6. `goto 7` jumps to the silent `let` at the end. After it executes, the program counter advances past the last expression and the program terminates.

`smol` exists primarily as an experiment in building a tiny interpreter.

It's not trying to be useful.

It's smol.

## Syntax

| Syntax         | Form                    | Description                                   | Result           |
| -------------- | ----------------------- | --------------------------------------------- | ---------------- |
| Integer        | `42`                    | Integer literal                               | `int`            |
| Boolean        | `true` / `false`        | Boolean literal                               | `bool`           |
| Variable       | `x`                     | Read a variable                               | Variable's value |
| Input          | `<->`                   | Read an integer from stdin                    | `int`            |
| Let            | `( let x expr )`        | Assign/evaluate `expr` and store it in `x`    | Value of `expr`  |
| Addition       | `( + a b )`             | Integer addition                              | `int`            |
| Subtraction    | `( - a b )`             | Integer subtraction                           | `int`            |
| Multiplication | `( * a b )`             | Integer multiplication                        | `int`            |
| Division       | `( / a b )`             | Integer division                              | `int`            |
| Modulo         | `( % a b )`             | Integer remainder                             | `int`            |
| Greater than   | `( > a b )`             | Compare two integers                          | `bool`           |
| Less than      | `( < a b )`             | Compare two integers                          | `bool`           |
| Greater/equal  | `( >= a b )`            | Compare two integers                          | `bool`           |
| Less/equal     | `( <= a b )`            | Compare two integers                          | `bool`           |
| Equality       | `( == a b )`            | Compare two values of the same type           | `bool`           |
| Inequality     | `( != a b )`            | Compare two values of the same type           | `bool`           |
| Logical OR     | `( \|\| a b )`          | Boolean OR                                    | `bool`           |
| Logical AND    | `( && a b )`            | Boolean AND                                   | `bool`           |
| Logical NOT    | `( ! expr )`            | Boolean negation                              | `bool`           |
| If             | `( if condition body )` | Evaluate `body` only when `condition` is true | Body's value     |
| Goto           | `( goto expr )`         | Jump to an expression number                  | Control flow     |

## Operators

| Operator | Arity | Operand types          | Result           |
| -------- | ----: | ---------------------- | ---------------- |
| `+`      |     2 | `int`, `int`           | `int`            |
| `-`      |     2 | `int`, `int`           | `int`            |
| `*`      |     2 | `int`, `int`           | `int`            |
| `/`      |     2 | `int`, `int`           | `int`            |
| `%`      |     2 | `int`, `int`           | `int`            |
| `>`      |     2 | `int`, `int`           | `bool`           |
| `<`      |     2 | `int`, `int`           | `bool`           |
| `>=`     |     2 | `int`, `int`           | `bool`           |
| `<=`     |     2 | `int`, `int`           | `bool`           |
| `==`     |     2 | same type              | `bool`           |
| `!=`     |     2 | same type              | `bool`           |
| `\|\|`   |     2 | `bool`, `bool`         | `bool`           |
| `&&`     |     2 | `bool`, `bool`         | `bool`           |
| `!`      |     1 | `bool`                 | `bool`           |
| `if`     |     2 | `bool`, any expression | expression value |
| `goto`   |     1 | `int`                  | control flow     |

## Notes

* One expression per line
* Only lines containing expressions count toward expression numbers
* Blank lines and comments do *not* count toward expression numbers
* `goto` targets are 1-based
* `goto` to a missing expression is an error; running off the end after the last expression is normal termination
* `let` does not print; other evaluated expressions do
* A false `if` skips its body and prints nothing
* A true `if` prints its body's value, even when that body is a `let`
* There is no `else`; use `if` and `goto`
* Tokens must be separated by whitespace
* Comments are whole-line only, starting with `;`
* `&&` and `||` evaluate both operands
* Division and modulo by zero produce an error

## Version
v0.1.0
