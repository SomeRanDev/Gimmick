package parsers.expr;

import ast.scope.Scope;
using ast.scope.ScopeMember;
import ast.typing.Type;

import parsers.Parser;
using parsers.expr.TypedExpression;
import parsers.expr.Literal;
import parsers.expr.Operator;
import parsers.expr.PrefixOperator;
import parsers.expr.SuffixOperator;
import parsers.expr.InfixOperator;

enum Expression {
	Prefix(op: PrefixOperator, expr: Expression, pos: Position);
	Suffix(op: SuffixOperator, expr: Expression, pos: Position);
	Infix(op: InfixOperator, lexpr: Expression, rexpr: Expression, pos: Position);
	Value(literal: Literal, pos: Position);
}

class ExpressionHelper {
	public static function getType(expression: Expression, scope: Scope, isPrelim: Bool, accessor: Null<Type> = null): Null<TypedExpression> {
		switch(expression) {
			case Prefix(op, expr, pos): {
				final typedExpr = getType(expr, scope, isPrelim);
				if(typedExpr != null) {
					final result = op.findReturnType(typedExpr.getType());
					if(result != null) {
						return Prefix(op, typedExpr, pos, result);
					} else if(!isPrelim) {
						Error.addErrorFromPos(ErrorType.InvalidPrefixOperator, pos, [typedExpr.getType().toString()]);
					}
				}
				return null;
			}
			case Suffix(op, expr, pos): {
				final typedExpr = getType(expr, scope, isPrelim);
				if(typedExpr != null) {
					final type = typedExpr.getType();
					final result = op.findReturnType(type);
					if(result != null) {
						return Suffix(op, typedExpr, pos, result);
					} else if(!isPrelim) {
						Error.addErrorFromPos(ErrorType.InvalidSuffixOperator, pos, [type.toString()]);
					}
				}
				return null;
			}
			case Infix(op, lexpr, rexpr, pos): {
				final lexprTyped = getType(lexpr, scope, isPrelim);
				if(lexprTyped != null) {
					final rexprTyped = getType(rexpr, scope, isPrelim, op.isAccessor() ? lexprTyped.getType() : null);
					if(rexprTyped != null) {
						final rType = rexprTyped.getType();
						final lType = lexprTyped.getType();
						final result = op.isAccessor() ? rType : op.findReturnType(lType, rType);
						if(result != null) {
							return Infix(op, lexprTyped, rexprTyped, pos, result);
						} else if(!isPrelim) {
							Error.addErrorFromPos(ErrorType.InvalidInfixOperator, pos, [lType.toString(), rType.toString()]);
						}
					}
				}
				
				return null;
			}
			case Value(literal, pos): {
				var result = Type.fromLiteral(literal, scope);
				if(result != null) {
					var replacement: Null<Literal> = null;
					var varName: Null<String> = null;
					switch(result.type) {
						case UnknownNamed(name): {
							varName = name;
							if(accessor == null) {
								final member = scope.findMember(name);
								if(member != null) {
									result = member.getType();
									switch(member) {
										case ScopeMember.Variable(varMember): {
											replacement = Name(name, varMember.get().getNamespaces());
										}
										default: {}
									}
								} else {
									result = null;
								}
							} else {
								result = accessor.findAccessorMember(name);
							}
						}
						default: {}
					}

					if(result != null) {
						return Value(replacement == null ? literal : replacement, pos, result);
					} else if(!isPrelim) {
						if(accessor == null) {
							Error.addErrorFromPos(ErrorType.UnknownVariable, pos, [varName == null ? "" : varName]);
						} else {
							Error.addErrorFromPos(ErrorType.UnknownMember, pos, [varName == null ? "" : varName, accessor.toString()]);
						}
					}
				} else if(!isPrelim) {
					Error.addErrorFromPos(ErrorType.InvalidValue, pos);
				}
			}
		}
		return null;
	}

	public static function getPosition(expr: Expression): Position {
		return switch(expr) {
			case Prefix(_, _, pos): pos;
			case Suffix(_, _, pos): pos;
			case Infix(_, _, _, pos): pos;
			case Value(_, pos): pos;
		};
	}
}
