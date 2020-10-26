package interpreter;

using interpreter.Variant;
import interpreter.RuntimeScope;

import parsers.Error;
import parsers.ErrorType;

import parsers.expr.Expression;
import parsers.expr.TypedExpression;
import parsers.expr.PrefixOperator;
import parsers.expr.SuffixOperator;
import parsers.expr.InfixOperator;
import parsers.expr.CallOperator;
import parsers.expr.Literal;
import parsers.expr.Position;
import parsers.expr.QuantumExpression;

class ExpressionInterpreter {
	public static function interpret(expr: QuantumExpression, data: RuntimeScope): Null<Variant> {
		return switch(expr) {
			case Untyped(e): {
				return interpretUntyped(e, data);
			}
			case Typed(e): {
				return interpretTyped(e, data);
			}
		}
	}

	public static function interpretTyped(expr: TypedExpression, data: RuntimeScope): Null<Variant> {
		return switch(expr) {
			case Prefix(op, expr, pos, _): interpretPrefix(op, expr, pos, data);
			case Suffix(op, expr, pos, _): interpretSuffix(op, expr, pos, data);
			case Infix(op, lexpr, rexpr, pos, _): interpretInfix(op, lexpr, rexpr, pos, data);
			case Value(literal, pos, _): interpretLiteral(literal, pos, data);
			default: null;
		}
	}

	public static function interpretUntyped(expr: Expression, data: RuntimeScope): Null<Variant> {
		return switch(expr) {
			case Prefix(op, expr, pos): interpretPrefix(op, expr, pos, data);
			case Suffix(op, expr, pos): interpretSuffix(op, expr, pos, data);
			case Infix(op, lexpr, rexpr, pos): interpretInfix(op, lexpr, rexpr, pos, data);
			case Value(literal, pos): interpretLiteral(literal, pos, data);
			default: null;
		}
	}

	public static function interpretPrefix(op: PrefixOperator, expr: QuantumExpression, pos: Position, data: RuntimeScope): Null<Variant> {
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
		Error.addErrorFromPos(ErrorType.InvalidPrefixOperator, pos, [e.typeString()]);
		return null;
	}

	public static function interpretSuffix(op: SuffixOperator, expr: QuantumExpression, pos: Position, data: RuntimeScope): Null<Variant> {
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
		Error.addErrorFromPos(ErrorType.InvalidSuffixOperator, pos, [e.typeString()]);
		return null;
	}

	public static function interpretInfix(op: InfixOperator, lexpr: QuantumExpression, rexpr: QuantumExpression, pos: Position, data: RuntimeScope): Null<Variant> {
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
		Error.addErrorFromPos(ErrorType.InvalidInfixOperator, pos, [l.typeString(), r.typeString()]);
		return null;
	}

	public static function interpretLiteral(literal: Literal, pos: Position, data: RuntimeScope): Null<Variant> {
		switch(literal) {
			case Name(name, _): {
				final val = data.find(name);
				if(val != null) {
					return val;
				} else {
					Error.addErrorFromPos(ErrorType.UnknownVariable, pos);
					return null;
				}
			}
			case Variable(mem): {
				return interpretLiteral(Name(mem.name, null), pos, data);
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
		Error.addErrorFromPos(ErrorType.InterpreterUnknownLiteral, pos);
		return null;
	}
}
