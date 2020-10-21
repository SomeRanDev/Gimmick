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
import parsers.expr.CallOperator;

enum Expression {
	Prefix(op: PrefixOperator, expr: Expression, pos: Position);
	Suffix(op: SuffixOperator, expr: Expression, pos: Position);
	Infix(op: InfixOperator, lexpr: Expression, rexpr: Expression, pos: Position);
	Call(op: CallOperator, expr: Expression, params: Array<Expression>, pos: Position);
	Value(literal: Literal, pos: Position);
}

class ExpressionHelper {
	public static function getType(expression: Expression, parser: Parser, isPrelim: Bool, accessor: Null<Type> = null, incrementCall: Bool = false): Null<TypedExpression> {
		switch(expression) {
			case Prefix(op, expr, pos): {
				final typedExpr = getType(expr, parser, isPrelim);
				if(typedExpr != null) {
					final result = op.findReturnType(typedExpr.getType());
					if(result != null) {
						parser.onTypeUsed(result);
						return Prefix(op, typedExpr, pos, result);
					} else if(!isPrelim) {
						Error.addErrorFromPos(ErrorType.InvalidPrefixOperator, pos, [typedExpr.getType().toString()]);
					}
				}
				return null;
			}
			case Suffix(op, expr, pos): {
				final typedExpr = getType(expr, parser, isPrelim);
				if(typedExpr != null) {
					final type = typedExpr.getType();
					final result = op.findReturnType(type);
					if(result != null) {
						parser.onTypeUsed(result);
						return Suffix(op, typedExpr, pos, result);
					} else if(!isPrelim) {
						Error.addErrorFromPos(ErrorType.InvalidSuffixOperator, pos, [type.toString()]);
					}
				}
				return null;
			}
			case Infix(op, lexpr, rexpr, pos): {
				final lexprTyped = getType(lexpr, parser, isPrelim);
				if(lexprTyped != null) {
					final rexprTyped = getType(rexpr, parser, isPrelim, op.isAccessor() ? lexprTyped.getType() : null);
					if(rexprTyped != null) {
						final rType = rexprTyped.getType();
						final lType = lexprTyped.getType();
						final result = op.isAccessor() ? rType : op.findReturnType(lType, rType);
						if(result != null) {
							parser.onTypeUsed(result);
							return Infix(op, lexprTyped, rexprTyped, pos, result);
						} else if(!isPrelim) {
							Error.addErrorFromPos(ErrorType.InvalidInfixOperator, pos, [lType.toString(), rType.toString()]);
						}
					}
				}
				
				return null;
			}
			case Call(op, expr, params, pos): {
				final typedExpr = getType(expr, parser, isPrelim, null, op == CallOperators.Call);
				if(typedExpr != null) {

					final typedParams: Array<TypedExpression> = [];
					for(p in params) {
						final r = getType(p, parser, isPrelim);
						if(r != null) {
							typedParams.push(r);
						}
					}

					final type = typedExpr.getType();
					final result = op.findReturnType(type, typedParams.map(p -> p.getType()));
					if(result != null) {
						parser.onTypeUsed(result);
						return Call(op, typedExpr, typedParams, pos, result);
					} else if(!isPrelim) {
						Error.addErrorFromPos(ErrorType.InvalidCallOperator, pos, [type.toString()]);
					}
				}
				return null;
			}
			case Value(literal, pos): {
				var result = Type.fromLiteral(literal, parser.scope);
				if(result != null) {
					var replacement: Null<Literal> = null;
					var varName: Null<String> = null;
					switch(result.type) {
						case UnknownNamed(name): {
							varName = name;
							if(accessor == null) {
								final member = parser.scope.findMember(name);
								if(member != null) {
									result = member.getType();
									switch(member.type) {
										case ScopeMemberType.Variable(varMember): {
											replacement = Variable(varMember.get());
										}
										case ScopeMemberType.Function(funcMember): {
											replacement = Function(funcMember.get());
											if(incrementCall) {
												funcMember.get().incrementCallCount();
											}
										}
										case ScopeMemberType.GetSet(varMember): {
											replacement = GetSet(varMember.get());
										}
										default: {}
									}
								} else {
									result = null;
								}
							} else {
								result = accessor.findAccessorMemberType(name);
							}
						}
						default: {}
					}

					if(result != null) {
						parser.onTypeUsed(result);
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
			case Call(_, _, _, pos): pos;
		};
	}
}
