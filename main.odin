package main

import "base:runtime"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

Error :: enum {
	None = 0,
	File_Read_Failed,
	Out_Of_Memory,
	Unexpected_End_Of_Expression,
	Unexpected_Token,
	Invalid_Expression,
	Invalid_Operator,
	Expected_Bool,
	Expected_Int,
	Type_Mismatch,
	Division_By_Zero,
	Invalid_Goto_Target,
	Undefined_Variable,
	Input_Failed,
}

LParen :: struct {}
RParen :: struct {}
Plus :: struct {}
Minus :: struct {}
Mul :: struct {}
Div :: struct {}
Mod :: struct {}
Not :: struct {}
OrOr :: struct {}
AndAnd :: struct {}
GT :: struct {}
LT :: struct {}
EqEq :: struct {}
NotEq :: struct {}
GTEq :: struct {}
LTEq :: struct {}
Let :: struct {}
If :: struct {}
Goto :: struct {}
Input :: struct {}

Identifier :: struct {
	name : string,
}

Value :: union {
	int,
	bool,
}

Token :: union {
	LParen,
	RParen,
	Plus,
	Minus,
	Mul,
	Div,
	Mod,
	Not,
	GT,
	LT,
	EqEq,
	NotEq,
	GTEq,
	LTEq,
	OrOr,
	AndAnd,
	Value,
	Identifier,
	Let,
	If,
	Goto,
	Input,
}

UnaryOpKind :: enum {
	Not,
	Goto,
}

Unary :: struct {
	op :    UnaryOpKind,
	value : ^SExpr,
}

BinaryOpKind :: enum {
	Plus,
	Minus,
	Mul,
	Div,
	Mod,
	GT,
	LT,
	EqEq,
	NotEq,
	GTEq,
	LTEq,
	OrOr,
	AndAnd,
	If,
}

Binary :: struct {
	op : BinaryOpKind,
	a :  ^SExpr,
	b :  ^SExpr,
}

LetExpr :: struct {
	name :  string,
	value : ^SExpr,
}

Variable :: struct {
	name : string,
}

SExpr :: union {
	Unary,
	Binary,
	LetExpr,
	Variable,
	Value,
	Input,
}

EvalResult :: struct {
	value :  Value,
	goto :   bool,
	target : int,
	skip :   bool,
}

read_lines :: proc(
	path : string,
	allocator := context.allocator,
) -> (
	lines : [dynamic]string,
	file_data : []byte,
	err : Error,
) {
	file, read_err := os.read_entire_file(path, allocator)

	if read_err != nil {
		if _, ok := read_err.(runtime.Allocator_Error); ok {
			return nil, nil, .Out_Of_Memory
		}

		return nil, nil, .File_Read_Failed
	}

	lines_ok, lines_err := make([dynamic]string, allocator)

	if lines_err != nil {
		delete(file, allocator)
		return nil, nil, .Out_Of_Memory
	}

	file_str := string(file)

	for line in strings.split_lines_iterator(&file_str) {
		// Comments and new line handling
		line := strings.trim_space(line)
		if len(line) == 0 do continue
		if line[0] == ';' do continue
		if strings.contains(line, ";") {
			delete(lines_ok)
			delete(file, allocator)
			return nil, nil, .Unexpected_Token
		}

		_, append_err := append(&lines_ok, line)

		if append_err != nil {
			delete(lines_ok)
			delete(file, allocator)
			return nil, nil, .Out_Of_Memory
		}
	}

	return lines_ok, file, .None
}

split_tokens :: proc(
	line : ^string,
	allocator := context.allocator,
) -> (
	tokens : [dynamic]Token,
	err : Error,
) {
	toks, make_err := make([dynamic]Token, allocator)

	if make_err != nil {
		return nil, .Out_Of_Memory
	}

	for tok in strings.split_iterator(line, " ") {
		// Ignore empty tokens caused by multiple spaces.
		if len(tok) == 0 {
			continue
		}

		switch tok {
		case "(": if _, err := append(&toks, LParen{}); err != nil {
					delete(toks)
					return nil, .Out_Of_Memory
				}

		case ")": if _, err := append(&toks, RParen{}); err != nil {
					delete(toks)
					return nil, .Out_Of_Memory
				}

		case "+": if _, err := append(&toks, Plus{}); err != nil {
					delete(toks)
					return nil, .Out_Of_Memory
				}

		case "-": if _, err := append(&toks, Minus{}); err != nil {
					delete(toks)
					return nil, .Out_Of_Memory
				}

		case "*": if _, err := append(&toks, Mul{}); err != nil {
					delete(toks)
					return nil, .Out_Of_Memory
				}

		case "/": if _, err := append(&toks, Div{}); err != nil {
					delete(toks)
					return nil, .Out_Of_Memory
				}

		case "%": if _, err := append(&toks, Mod{}); err != nil {
					delete(toks)
					return nil, .Out_Of_Memory
				}

		case "!": if _, err := append(&toks, Not{}); err != nil {
					delete(toks)
					return nil, .Out_Of_Memory
				}

		case "||": if _, err := append(&toks, OrOr{}); err != nil {
					delete(toks)
					return nil, .Out_Of_Memory
				}

		case "&&": if _, err := append(&toks, AndAnd{}); err != nil {
					delete(toks)
					return nil, .Out_Of_Memory
				}

		case ">": if _, err := append(&toks, GT{}); err != nil {
					delete(toks)
					return nil, .Out_Of_Memory
				}

		case "<": if _, err := append(&toks, LT{}); err != nil {
					delete(toks)
					return nil, .Out_Of_Memory
				}

		case "==": if _, err := append(&toks, EqEq{}); err != nil {
					delete(toks)
					return nil, .Out_Of_Memory
				}

		case "!=": if _, err := append(&toks, NotEq{}); err != nil {
					delete(toks)
					return nil, .Out_Of_Memory
				}

		case ">=": if _, err := append(&toks, GTEq{}); err != nil {
					delete(toks)
					return nil, .Out_Of_Memory
				}

		case "<=": if _, err := append(&toks, LTEq{}); err != nil {
					delete(toks)
					return nil, .Out_Of_Memory
				}

		case "<->": if _, err := append(&toks, Input{}); err != nil {
					delete(toks)
					return nil, .Out_Of_Memory
				}

		case "true": if _, err := append(&toks, Value(true)); err != nil {
					delete(toks)
					return nil, .Out_Of_Memory
				}

		case "false": if _, err := append(&toks, Value(false)); err != nil {
					delete(toks)
					return nil, .Out_Of_Memory
				}

		case "let": if _, err := append(&toks, Let{}); err != nil {
					delete(toks)
					return nil, .Out_Of_Memory
				}

		case "if": if _, err := append(&toks, If{}); err != nil {
					delete(toks)
					return nil, .Out_Of_Memory
				}

		case "goto": if _, err := append(&toks, Goto{}); err != nil {
					delete(toks)
					return nil, .Out_Of_Memory
				}

		case:
			val, ok := strconv.parse_int(tok)

			if ok {
				if _, err := append(&toks, Value(val)); err != nil {
					delete(toks)
					return nil, .Out_Of_Memory
				}
			} else {
				// Anything that isn't a number or keyword is an identifier.
				if _, err := append(&toks, Identifier{name = tok}); err != nil {
					delete(toks)
					return nil, .Out_Of_Memory
				}
			}
		}
	}

	return toks, .None
}

parse_expr :: proc(toks : []Token, pos : ^int) -> (expr : SExpr, err : Error) {
	if pos^ >= len(toks) {
		return SExpr{}, .Unexpected_End_Of_Expression
	}

	tok := toks[pos^]
	pos^ += 1

	switch value in tok {
	case Value: return SExpr(value), .None

	case Identifier: return SExpr(Variable{name = value.name}), .None

	case Input: return SExpr(Input{}), .None

	case LParen:
		if pos^ >= len(toks) {
			return SExpr{}, .Unexpected_End_Of_Expression
		}

		op_tok := toks[pos^]
		pos^ += 1

		// ------------------------------------------------------------
		// (let IDENTIFIER EXPR)
		// ------------------------------------------------------------
		if _, ok := op_tok.(Let); ok {
			if pos^ >= len(toks) {
				return SExpr{}, .Unexpected_End_Of_Expression
			}

			name_tok := toks[pos^]
			pos^ += 1

			name, ok := name_tok.(Identifier)

			if !ok {
				return SExpr{}, .Unexpected_Token
			}

			value := new(SExpr)

			value^, err = parse_expr(toks, pos)

			if err != .None {
				return SExpr{}, err
			}

			if pos^ >= len(toks) {
				return SExpr{}, .Unexpected_End_Of_Expression
			}

			if _, ok := toks[pos^].(RParen); !ok {
				return SExpr{}, .Unexpected_Token
			}

			pos^ += 1

			return SExpr(LetExpr{name = name.name, value = value}), .None
		}

		// ------------------------------------------------------------
		// (! expr)
		// ------------------------------------------------------------
		if _, ok := op_tok.(Not); ok {
			value := new(SExpr)

			value^, err = parse_expr(toks, pos)

			if err != .None {
				return SExpr{}, err
			}

			if pos^ >= len(toks) {
				return SExpr{}, .Unexpected_End_Of_Expression
			}

			if _, ok := toks[pos^].(RParen); !ok {
				return SExpr{}, .Unexpected_Token
			}

			pos^ += 1

			return SExpr(Unary{op = .Not, value = value}), .None
		}

		// ------------------------------------------------------------
		// (goto expr)
		// ------------------------------------------------------------
		if _, ok := op_tok.(Goto); ok {
			value := new(SExpr)

			value^, err = parse_expr(toks, pos)

			if err != .None {
				return SExpr{}, err
			}

			if pos^ >= len(toks) {
				return SExpr{}, .Unexpected_End_Of_Expression
			}

			if _, ok := toks[pos^].(RParen); !ok {
				return SExpr{}, .Unexpected_Token
			}

			pos^ += 1

			return SExpr(Unary{op = .Goto, value = value}), .None
		}

		// ------------------------------------------------------------
		// (if condition body)
		// ------------------------------------------------------------
		if _, ok := op_tok.(If); ok {
			condition := new(SExpr)

			condition^, err = parse_expr(toks, pos)

			if err != .None {
				return SExpr{}, err
			}

			body := new(SExpr)

			body^, err = parse_expr(toks, pos)

			if err != .None {
				return SExpr{}, err
			}

			if pos^ >= len(toks) {
				return SExpr{}, .Unexpected_End_Of_Expression
			}

			if _, ok := toks[pos^].(RParen); !ok {
				return SExpr{}, .Unexpected_Token
			}

			pos^ += 1

			return SExpr(Binary{op = .If, a = condition, b = body}), .None
		}

		// ------------------------------------------------------------
		// Binary operators
		// ------------------------------------------------------------
		op : BinaryOpKind

		#partial switch _ in op_tok {
		case Plus: op = .Plus
		case Minus: op = .Minus
		case Mul: op = .Mul
		case Div: op = .Div
		case Mod: op = .Mod
		case GT: op = .GT
		case LT: op = .LT
		case EqEq: op = .EqEq
		case NotEq: op = .NotEq
		case GTEq: op = .GTEq
		case LTEq: op = .LTEq
		case OrOr: op = .OrOr
		case AndAnd: op = .AndAnd

		case: return SExpr{}, .Invalid_Operator
		}

		a := new(SExpr)

		a^, err = parse_expr(toks, pos)

		if err != .None {
			return SExpr{}, err
		}

		b := new(SExpr)

		b^, err = parse_expr(toks, pos)

		if err != .None {
			return SExpr{}, err
		}

		if pos^ >= len(toks) {
			return SExpr{}, .Unexpected_End_Of_Expression
		}

		if _, ok := toks[pos^].(RParen); !ok {
			return SExpr{}, .Unexpected_Token
		}

		pos^ += 1

		return SExpr(Binary{op = op, a = a, b = b}), .None

	case RParen,
		 Plus,
		 Minus,
		 Mul,
		 Div,
		 Mod,
		 Not,
		 GT,
		 LT,
		 EqEq,
		 NotEq,
		 GTEq,
		 LTEq,
		 OrOr,
		 AndAnd,
		 Let,
		 If,
		 Goto:
		return SExpr{}, .Unexpected_Token
	}

	return SExpr{}, .Invalid_Expression
}

parse_line :: proc(toks : []Token) -> (SExpr, Error) {
	if len(toks) == 0 {
		return SExpr{}, .Invalid_Expression
	}

	pos := 0

	expr, err := parse_expr(toks, &pos)

	if err != .None {
		return SExpr{}, err
	}

	if pos != len(toks) {
		return SExpr{}, .Unexpected_Token
	}

	return expr, .None
}

read_input_int :: proc() -> (value : int, err : Error) {
	buffer, make_err := make([dynamic]u8)
	if make_err != nil {
		return 0, .Out_Of_Memory
	}
	defer delete(buffer)
	for {
		var, byte_buffer : [1]u8
		n, read_err := os.read(os.stdin, byte_buffer[:])
		if read_err != nil {
			return 0, .Input_Failed
		}
		if n == 0 {
			break
		}
		ch := byte_buffer[0]
		if ch == '\n' {
			break
		}
		if ch == '\r' {
			continue
		}
		if _, append_err := append(&buffer, ch); append_err != nil {
			return 0, .Out_Of_Memory
		}
	}
	input := string(buffer[:])
	parsed, ok := strconv.parse_int(strings.trim_space(input))
	if !ok {
		return 0, .Input_Failed
	}
	value = parsed
	return value, .None
}

eval :: proc(expr : SExpr, env : ^map[string]Value) -> (EvalResult, Error) {
	#partial switch e in expr {
	// ------------------------------------------------------------
	// Input
	// ------------------------------------------------------------
	case Input:
		fmt.print("> ")
		value, input_err := read_input_int()

		if input_err != .None {
			return EvalResult{}, input_err
		}

		return EvalResult{value = Value(value)}, .None

	// ------------------------------------------------------------
	// Variable lookup
	// ------------------------------------------------------------
	case Variable:
		value, ok := env^[e.name]

		if !ok {
			return EvalResult{}, .Undefined_Variable
		}

		return EvalResult{value = value}, .None

	// ------------------------------------------------------------
	// let
	// ------------------------------------------------------------
	case LetExpr:
		result, err := eval(e.value^, env)

		if err != .None {
			return EvalResult{}, err
		}

		if result.goto {
			return result, .None
		}

		env^[e.name] = result.value

		return result, .None

	// ------------------------------------------------------------
	// Unary operations
	// ------------------------------------------------------------
	case Unary: #partial switch e.op {
			case .Not:
				result, err := eval(e.value^, env)

				if err != .None {
					return EvalResult{}, err
				}

				if result.goto {
					return result, .None
				}

				#partial switch v in result.value {
				case bool: return EvalResult{value = !v}, .None

				case: return EvalResult{}, .Expected_Bool
				}

			case .Goto:
				result, err := eval(e.value^, env)

				if err != .None {
					return EvalResult{}, err
				}

				if result.goto {
					return result, .None
				}

				#partial switch v in result.value {
				case int: return EvalResult{goto = true, target = v - 1}, .None

				case: return EvalResult{}, .Expected_Int
				}
			}

	// ------------------------------------------------------------
	// Binary operations
	// ------------------------------------------------------------
	case Binary:
		// `if` must short-circuit.
		// Do not evaluate the body when the condition is false.
		if e.op == .If {
			condition, err := eval(e.a^, env)

			if err != .None {
				return EvalResult{}, err
			}

			if condition.goto {
				return condition, .None
			}

			#partial switch v in condition.value {
			case bool:
				if !v {
					return EvalResult{skip = true}, .None
				}

				return eval(e.b^, env)

			case: return EvalResult{}, .Expected_Bool
			}
		}

		a, err := eval(e.a^, env)

		if err != .None {
			return EvalResult{}, err
		}

		if a.goto {
			return a, .None
		}

		b, eval_err := eval(e.b^, env)

		if eval_err != .None {
			return EvalResult{}, eval_err
		}

		if b.goto {
			return b, .None
		}

		#partial switch e.op {
		// --------------------------------------------------------
		// +
		// --------------------------------------------------------
		case .Plus: #partial switch av in a.value {
				case int: #partial switch bv in b.value {
						case int: return EvalResult{value = av + bv}, .None

						case: return EvalResult{}, .Expected_Int
						}

				case: return EvalResult{}, .Expected_Int
				}

		// --------------------------------------------------------
		// -
		// --------------------------------------------------------
		case .Minus: #partial switch av in a.value {
				case int: #partial switch bv in b.value {
						case int: return EvalResult{value = av - bv}, .None

						case: return EvalResult{}, .Expected_Int
						}

				case: return EvalResult{}, .Expected_Int
				}

		// --------------------------------------------------------
		// *
		// --------------------------------------------------------
		case .Mul: #partial switch av in a.value {
				case int: #partial switch bv in b.value {
						case int: return EvalResult{value = av * bv}, .None

						case: return EvalResult{}, .Expected_Int
						}

				case: return EvalResult{}, .Expected_Int
				}

		// --------------------------------------------------------
		// /
		// --------------------------------------------------------
		case .Div: #partial switch av in a.value {
				case int: #partial switch bv in b.value {
						case int:
							if bv == 0 {
								return EvalResult{}, .Division_By_Zero
							}

							return EvalResult{value = av / bv}, .None

						case: return EvalResult{}, .Expected_Int
						}

				case: return EvalResult{}, .Expected_Int
				}

		// --------------------------------------------------------
		// %
		// --------------------------------------------------------
		case .Mod: #partial switch av in a.value {
				case int: #partial switch bv in b.value {
						case int:
							if bv == 0 {
								return EvalResult{}, .Division_By_Zero
							}

							return EvalResult{value = av % bv}, .None

						case: return EvalResult{}, .Expected_Int
						}

				case: return EvalResult{}, .Expected_Int
				}

		// --------------------------------------------------------
		// >
		// --------------------------------------------------------
		case .GT: #partial switch av in a.value {
				case int: #partial switch bv in b.value {
						case int: return EvalResult{value = av > bv}, .None

						case: return EvalResult{}, .Expected_Int
						}

				case: return EvalResult{}, .Expected_Int
				}

		// --------------------------------------------------------
		// <
		// --------------------------------------------------------
		case .LT: #partial switch av in a.value {
				case int: #partial switch bv in b.value {
						case int: return EvalResult{value = av < bv}, .None

						case: return EvalResult{}, .Expected_Int
						}

				case: return EvalResult{}, .Expected_Int
				}

		// --------------------------------------------------------
		// >=
		// --------------------------------------------------------
		case .GTEq: #partial switch av in a.value {
				case int: #partial switch bv in b.value {
						case int: return EvalResult{value = av >= bv}, .None

						case: return EvalResult{}, .Expected_Int
						}

				case: return EvalResult{}, .Expected_Int
				}

		// --------------------------------------------------------
		// <=
		// --------------------------------------------------------
		case .LTEq: #partial switch av in a.value {
				case int: #partial switch bv in b.value {
						case int: return EvalResult{value = av <= bv}, .None

						case: return EvalResult{}, .Expected_Int
						}

				case: return EvalResult{}, .Expected_Int
				}

		// --------------------------------------------------------
		// ||
		// --------------------------------------------------------
		case .OrOr: #partial switch av in a.value {
				case bool: #partial switch bv in b.value {
						case bool: return EvalResult{value = av || bv}, .None

						case: return EvalResult{}, .Expected_Bool
						}

				case: return EvalResult{}, .Expected_Bool
				}

		// --------------------------------------------------------
		// &&
		// --------------------------------------------------------
		case .AndAnd: #partial switch av in a.value {
				case bool: #partial switch bv in b.value {
						case bool: return EvalResult{value = av && bv}, .None

						case: return EvalResult{}, .Expected_Bool
						}

				case: return EvalResult{}, .Expected_Bool
				}

		// --------------------------------------------------------
		// ==
		// --------------------------------------------------------
		case .EqEq: #partial switch av in a.value {
				case int: #partial switch bv in b.value {
						case int: return EvalResult{value = av == bv}, .None

						case bool: return EvalResult{}, .Type_Mismatch
						}

				case bool: #partial switch bv in b.value {
						case bool: return EvalResult{value = av == bv}, .None

						case int: return EvalResult{}, .Type_Mismatch
						}
				}

		// --------------------------------------------------------
		// !=
		// --------------------------------------------------------
		case .NotEq: #partial switch av in a.value {
				case int: #partial switch bv in b.value {
						case int: return EvalResult{value = av != bv}, .None

						case bool: return EvalResult{}, .Type_Mismatch
						}

				case bool: #partial switch bv in b.value {
						case bool: return EvalResult{value = av != bv}, .None

						case int: return EvalResult{}, .Type_Mismatch
						}
				}
		}

	// ------------------------------------------------------------
	// Literal value
	// ------------------------------------------------------------
	case Value: return EvalResult{value = e}, .None
	}

	return EvalResult{}, .Invalid_Expression
}

main :: proc() {
	if len(os.args) < 2 {
		fmt.eprintln("missing input file")
		return
	}

	lines, data, err := read_lines(os.args[1])

	if err != .None {
		fmt.eprintln("error:", err)
		return
	}

	defer {
		delete(lines)
		delete(data)
	}

	exprs, make_err := make([dynamic]SExpr)

	if make_err != nil {
		fmt.eprintln("error:", Error.Out_Of_Memory)
		return
	}

	defer delete(exprs)

	// ------------------------------------------------------------
	// Parse every line
	// ------------------------------------------------------------
	for &line in lines {
		toks, err := split_tokens(&line)

		if err != .None {
			fmt.eprintln("error:", err)
			return
		}

		expr, parse_err := parse_line(toks[:])

		delete(toks)

		if parse_err != .None {
			fmt.eprintln("error:", parse_err)
			return
		}

		if _, append_err := append(&exprs, expr); append_err != nil {
			fmt.eprintln("error:", Error.Out_Of_Memory)
			return
		}
	}

	// ------------------------------------------------------------
	// Runtime environment
	// ------------------------------------------------------------
	env := make(map[string]Value)

	defer delete(env)

	// ------------------------------------------------------------
	// Execute
	// ------------------------------------------------------------
	pc := 0

	for pc < len(exprs) {
		result, err := eval(exprs[pc], &env)

		if err != .None {
			fmt.eprintln("error:", err)
			return
		}

		if result.goto {
			if result.target < 0 || result.target >= len(exprs) {
				fmt.eprintln("error:", Error.Invalid_Goto_Target)
				return
			}

			pc = result.target
			continue
		}

		// `let` and false `if` produce no output.
		if !result.skip {
			#partial switch _ in exprs[pc] {
			case LetExpr:
			// Do nothing.

			case: fmt.println(result.value)
			}
		}

		pc += 1
	}
}
