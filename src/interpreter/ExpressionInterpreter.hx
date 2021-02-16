package interpreter;

using haxe.EnumTools;

using interpreter.Variant;
import interpreter.RuntimeScope;
import interpreter.ScopeInterpreter;

import parsers.error.Error;
import parsers.error.ErrorType;

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
			case Call(op, expr, params, pos, _): interpretCall(op, expr, params.map(p -> new QuantumExpression(QuantumExpressionInternal.Typed(p))), pos, data);
			case Value(literal, pos, _): interpretLiteral(literal, pos, data);
			default: null;
		}
	}

	public static function interpretUntyped(expr: Expression, data: RuntimeScope): Null<Variant> {
		return switch(expr) {
			case Prefix(op, expr, pos): interpretPrefix(op, expr, pos, data);
			case Suffix(op, expr, pos): interpretSuffix(op, expr, pos, data);
			case Infix(op, lexpr, rexpr, pos): interpretInfix(op, lexpr, rexpr, pos, data);
			case Call(op, expr, params, pos): interpretCall(op, expr, params.map(p -> new QuantumExpression(QuantumExpressionInternal.Untyped(p))), pos, data);
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
		if(op.op == "=") {
			return interpretAssignment(lexpr, rexpr, pos, data);
		} else if(op.op == ".") {
			return interpretAccess(lexpr, rexpr, pos, data);
		}
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

	public static function interpretCall(op: CallOperator, expr: QuantumExpression, params: Array<QuantumExpression>, pos: Position, data: RuntimeScope): Null<Variant> {
		final e = interpret(expr, data);
		if(e == null) return null;
		final args = [];
		for(p in params) {
			final variant = interpret(p, data);
			if(variant != null) {
				args.push(variant);
			} else {
				return null;
			}
		}

		switch(op.op) {
			case "(": {
				// TODO: check if provided arguments match the function header
				switch(e) {
					case Function(members, names, t): {
						final scope = data.fromTopScope();
						var index = 0;
						for(n in names) {
							final val = args[index];
							if(val != null) {
								scope.add(n, val);
							}
							index++;
						}
						final resultInfo = ScopeInterpreter.interpret(members, scope);
						if(resultInfo != null) {
							return resultInfo.returnValue;
						}
					}
					case NativeFunction(func, t): {
						return func(null, args);
					}
					default: {
						Error.addErrorFromPos(ErrorType.InterpreterCannotCallType, pos);
					}
				}
			}
			case "[": {
				switch(e) {
					case Str(str): {
						if(args.length == 1 && args[0].isNumber()) {
							final index = args[0].toInt();
							if(index >= 0 && index < str.length) {
								return Str(str.charAt(index));
							} else {
								Error.addErrorFromPos(ErrorType.InterpreterAccessOutsideStringSize, pos, [
									Std.string(index),
									Std.string(str.length)
								]);
							}
						} else {
							Error.addErrorFromPos(ErrorType.InterpreterArrayAccessExpectsOneNumber, pos);
						}
					}
					case List(list, t): {
						if(args.length == 1 && args[0].isNumber()) {
							final index = args[0].toInt();
							if(index >= 0 && index < list.length) {
								return list[index];
							} else {
								Error.addErrorFromPos(ErrorType.InterpreterAccessOutsideArraySize, pos, [
									Std.string(index),
									Std.string(list.length)
								]);
							}
						} else {
							Error.addErrorFromPos(ErrorType.InterpreterArrayAccessExpectsOneNumber, pos);
						}
					}
					default: {}
				}
			}
		}

		return null;
	}

	public static function interpretAssignment(lexpr: QuantumExpression, rexpr: QuantumExpression, pos: Position, data: RuntimeScope): Null<Variant> {
		final name = getExpressionName(lexpr);
		if(name != null) {
			final r = interpret(rexpr, data);
			final currVal = data.find(name);
			if(r != null && currVal != null && r.type() == currVal.type()) {
				data.replace(name, r);
				return r;
			} else {
				Error.addErrorFromPos(ErrorType.InterpreterCannotAssignDifferentTypes, pos, [
					r != null ? r.typeString() : "null",
					currVal != null ? currVal.typeString() : "null",
				]);
				return null;
			}
		}
		Error.addErrorFromPos(ErrorType.InterpreterInvalidLExpr, pos);
		return null;
	}

	public static function interpretAccess(lexpr: QuantumExpression, rexpr: QuantumExpression, pos: Position, data: RuntimeScope): Null<Variant> {
		final e = interpret(lexpr, data);
		if(e == null) return null;
		final name = getExpressionName(rexpr);
		if(name == null) {
			Error.addErrorFromPos(ErrorType.InterpreterInvalidAccessor, pos);
		}
		final result = switch(e.type()) {
			case TBool: {
				null;
			}
			case TNum: {
				null;
			}
			case TStr: {
				if(name == "string_length") Num(e.toString().length);
				else null;
			}
			case TList(t): {
				null;
			}
			case TNullable(t): {
				null;
			}
			case TFunction(params, returnType): {
				null;
			}
		}
		return result;
	}

	public static function getExpressionName(expr: QuantumExpression): Null<String> {
		final literal: Null<Literal> = switch(expr) {
			case Typed(texpr): {
				switch(texpr) {
					case Value(literal, _, _): literal;
					default: null;
				}
			}
			case Untyped(expr): {
				switch(expr) {
					case Value(literal, _): literal;
					default: null;
				}
			}
		}
		if(literal != null) {
			final name = switch(literal) {
				case Name(name, _): name;
				case Variable(vari): vari.name;
				case Function(func): func.name;
				case GetSet(getset): getset.name;
				default: null;
			}
			return name;
		}
		return null;
	}

	public static function interpretLiteral(literal: Literal, pos: Position, data: RuntimeScope): Null<Variant> {
		switch(literal) {
			case Name(name, _): {
				final val = data.find(name);
				if(val != null) {
					return val;
				} else {
					Error.addErrorFromPos(ErrorType.UnknownVariable, pos, [name]);
					return null;
				}
			}
			case Variable(mem): {
				return interpretLiteral(Name(mem.name, null), pos, data);
			}
			case Function(mem): {
				return interpretLiteral(Name(mem.name, null), pos, data);
			}
			case GetSet(mem): {
				return interpretLiteral(Name(mem.name, null), pos, data);
			}
			case Boolean(value): {
				return Bool(value);
			}
			case Number(number, format, type): {
				final numValue = Std.parseInt(number);
				if(numValue != null) {
					return Num(numValue);
				} else {
					// TODO: Error, could not parse number value "number" (string)
				}
			}
			case String(content, isMultiline, isRaw): {
				return Str(content);
			}
			case List(exprs): {
				final variants: Array<Variant> = [];
				var variantListType: Null<VariantType> = null;
				for(e in exprs) {
					final currVariant = interpret(e, data);
					if(currVariant != null) {
						final currVariantType: VariantType = currVariant.type();
						if(variantListType == null) variantListType = currVariantType;
						if(variantListType != currVariantType) {
							Error.addErrorFromPos(ErrorType.InterpreterLiteralListValuesDoNotMatch, pos, [
								VariantHelper.typeToString(currVariantType),
								VariantHelper.typeToString(variantListType)
							]);
							return null;
						}
						variants.push(currVariant);
					}
				}
				if(variantListType != null) {
					return List(variants, variantListType);
				} else {
					// TODO: Error could not determine list type
				}
			}
			default: {}
		}
		Error.addErrorFromPos(ErrorType.InterpreterUnknownLiteral, pos);
		return null;
	}
}
