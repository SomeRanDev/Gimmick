package interpreter;

using interpreter.Variant;

import parsers.expr.Expression;
import parsers.expr.PrefixOperator;
import parsers.expr.SuffixOperator;
import parsers.expr.InfixOperator;
import parsers.expr.CallOperator;
import parsers.expr.Literal;

class Interpreter {
	public static function interpret(expr: Expression, data: Map<String,Variant>): Null<Variant> {
		return switch(expr) {
			case Prefix(op, expr, _): interpretPrefix(op, expr, data);
			case Suffix(op, expr, _): interpretSuffix(op, expr, data);
			case Infix(op, lexpr, rexpr, _): interpretInfix(op, lexpr, rexpr, data);
			case Value(literal, _): interpretLiteral(literal, data);
			default: null;
		}
	}

	public static function interpretPrefix(op: PrefixOperator, expr: Expression, data: Map<String,Variant>): Null<Variant> {
		final e = interpret(expr, data);
		if(e == null) return null;
		switch(op.op) {
			case "+": {
				if(e.isNumber()) {
					return Num(e.toNumber());
				}
			}
			case "-": {
				if(e.isNumber()) {
					return Num(-e.toNumber());
				}
			}
			case "!": {
				if(e.isBool()) {
					return Bool(!e.toBool());
				}
			}
			case "~": {
				if(e.isNumber()) {
					return Num(~e.toInt());
				}
			}
			case "++": {
				if(e.isNumber()) {
					return Num(e.toNumber() + 1);
				}
			}
			case "--": {
				if(e.isNumber()) {
					return Num(e.toNumber() - 1);
				}
			}
		}
		return null;
	}

	public static function interpretSuffix(op: SuffixOperator, expr: Expression, data: Map<String,Variant>): Null<Variant> {
		final e = interpret(expr, data);
		if(e == null) return null;
		switch(op.op) {
			case "++": {
				if(e.isNumber()) {
					return Num(e.toNumber() + 1);
				}
			}
			case "--": {
				if(e.isNumber()) {
					return Num(e.toNumber() - 1);
				}
			}
		}
		return null;
	}

	public static function interpretInfix(op: InfixOperator, lexpr: Expression, rexpr: Expression, data: Map<String,Variant>): Null<Variant> {
		final l = interpret(lexpr, data);
		final r = interpret(rexpr, data);
		if(l == null || r == null) return null;
		switch(op.op) {
			case "*": {
				if(l.isNumber() && r.isNumber()) {
					return Num(l.toNumber() * r.toNumber());
				}
			}
			case "/": {
				if(l.isNumber() && r.isNumber()) {
					return Num(l.toNumber() / r.toNumber());
				}
			}
			case "%": {
				if(l.isNumber() && r.isNumber()) {
					return Num(l.toInt() % r.toInt());
				}
			}
			case "+": {
				if(l.isNumber() && r.isNumber()) {
					return Num(l.toNumber() + r.toNumber());
				} else if(l.isString() && r.isNumber()) {
					return Str(l.toString() + Std.string(r.toNumber()));
				} else if(l.isNumber() && r.isString()) {
					return Str(Std.string(l.toNumber()) + r.toString());
				} else if(l.isString() && r.isString()) {
					return Str(l.toString() + r.toString());
				}
			}
			case "-": {
				if(l.isNumber() && r.isNumber()) {
					return Num(l.toNumber() - r.toNumber());
				}
			}
			case "<": {
				if(l.isNumber() && r.isNumber()) {
					return Bool(l.toNumber() < r.toNumber());
				}
			}
			case "<=": {
				if(l.isNumber() && r.isNumber()) {
					return Bool(l.toNumber() <= r.toNumber());
				}
			}
			case ">": {
				if(l.isNumber() && r.isNumber()) {
					return Bool(l.toNumber() > r.toNumber());
				}
			}
			case ">=": {
				if(l.isNumber() && r.isNumber()) {
					return Bool(l.toNumber() >= r.toNumber());
				}
			}
			case "==": {
				if(l.isNumber() && r.isNumber()) {
					return Bool(l.toNumber() == r.toNumber());
				} else if(l.isString() && r.isString()) {
					return Bool(l.toString() == r.toString());
				} else if(l.isBool() && r.isBool()) {
					return Bool(l.toBool() == r.toBool());
				}
				return Bool(false);
			}
			case "!=": {
				if(l.isNumber() && r.isNumber()) {
					return Bool(l.toNumber() != r.toNumber());
				} else if(l.isString() && r.isString()) {
					return Bool(l.toString() != r.toString());
				} else if(l.isBool() && r.isBool()) {
					return Bool(l.toBool() != r.toBool());
				}
				return Bool(true);
			}
			case "&": {
				if(l.isNumber() && r.isNumber()) {
					return Num(l.toInt() & r.toInt());
				}
			}
			case "^": {
				if(l.isNumber() && r.isNumber()) {
					return Num(l.toInt() ^ r.toInt());
				}
			}
			case "|": {
				if(l.isNumber() && r.isNumber()) {
					return Num(l.toInt() | r.toInt());
				}
			}
			case "&&": {
				if(l.isBool() && r.isBool()) {
					return Bool(l.toBool() && r.toBool());
				}
			}
			case "||": {
				if(l.isBool() && r.isBool()) {
					return Bool(l.toBool() || r.toBool());
				}
			}
		}
		return null;
	}

	public static function interpretLiteral(literal: Literal, data: Map<String,Variant>): Null<Variant> {
		switch(literal) {
			case Name(name, _): {
				if(data.exists(name)) {
					return data[name];
				}
			}
			case Boolean(value): {
				return Bool(value);
			}
			case Number(number, format, type): {
				return Num(Std.parseInt(number));
			}
			case String(content, isMultiline, isRaw): {
				return Str(content);
			}
			default: {}
		}
		return null;
	}
}
