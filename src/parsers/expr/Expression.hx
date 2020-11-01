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

enum TypingMode {
	Normal;
	Preliminary;
	Typeless;
}

class ExpressionTypingContext {
	public var incrementCall(default, null): Bool;
	public var isStaticExtension(default, null): Bool;
	public var prependedArgs(default, null): Null<Array<TypedExpression>>;

	public function new(incrementCall: Bool) {
		this.incrementCall = incrementCall;
		isStaticExtension = false;
		prependedArgs = null;
	}

	public function setIsStaticExtension() {
		isStaticExtension = true;
	}

	public function setPrependedArguments(prependedArgs: Array<TypedExpression>) {
		this.prependedArgs = prependedArgs;
	}
}

class ExpressionHelper {
	var parser: Parser;
	var mode: TypingMode;
	var isInterpret: Bool;
	var thisType: Null<Type>;
	var convertAssignmentToArgument: Bool;
	var exprStack: Array<Expression>;

	public function new(parser: Parser, mode: TypingMode = Normal, isInterpret: Bool = false, thisType: Null<Type> = null) {
		this.parser = parser;
		this.mode = mode;
		this.isInterpret = isInterpret;
		this.thisType = thisType != null ? Type.Pointer(thisType) : null;
		convertAssignmentToArgument = false;
		exprStack = [];
	}

	public function isAssignment(): Bool {
		if(exprStack.length >= 2) {
			final test = exprStack[exprStack.length - 2];
			switch(test) {
				case Infix(op, _, _, _): {
					if(op.op == "=") return true;
					else if(op.op != ".") return false;
				}
				default: return false;
			}
		}
		if(exprStack.length >= 3) {
			final test = exprStack[exprStack.length - 3];
			switch(test) {
				case Infix(op, _, _, _): {
					if(op.op == "=") return true;
					else return false;
				}
				default: return false;
			}
		}
		return false;
	}

	public function getInternalTypeStacked(expression: Expression, accessor: Null<TypedExpression> = null, context: Null<ExpressionTypingContext> = null): Null<TypedExpression> {
		exprStack.push(expression);
		final result = getInternalType(expression, accessor, context);
		exprStack.pop();
		return result;
	}

	public function getInternalType(expression: Expression, accessor: Null<TypedExpression> = null, context: Null<ExpressionTypingContext> = null): Null<TypedExpression> {
		final isPrelim = mode != Normal;
		final isUntyped = mode == Typeless;
		switch(expression) {
			case Prefix(op, expr, pos): {
				final typedExpr = getInternalTypeStacked(expr);
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
				final typedExpr = getInternalTypeStacked(expr);
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
				final lexprTyped = getInternalTypeStacked(lexpr);
				if(lexprTyped != null) {
					final accessContext = new ExpressionTypingContext(false);
					final rexprTyped = getInternalTypeStacked(rexpr, op.isAccessor() ? lexprTyped : null, accessContext);
					if(rexprTyped != null) {
						if(op.op == "=" && convertAssignmentToArgument) {
							convertAssignmentToArgument = false;
							switch(lexprTyped) {
								case Call(op, expr, params, pos, t): {
									params.push(rexprTyped);
									return Call(op, expr, params, pos, t);
								}
								default: {}
							}
						}
						final rType = rexprTyped.getType();
						final lType = op.isAccessor() ? null : lexprTyped.getType();
						final result = op.isAccessor() ? rType : @:nullSafety(Off) op.findReturnType(lType, rType);
						if(result != null) {
							parser.onTypeUsed(result);
							if(!isInterpret && accessContext != null && accessContext.isStaticExtension) {
								if(context != null) context.setPrependedArguments([lexprTyped]);
								return rexprTyped;
							}
							return Infix(op, lexprTyped, rexprTyped, pos, result);
						} else if(!isPrelim) {
							final lTypeErr = lType == null ? lexprTyped.getType().toString() : lType.toString();
							Error.addErrorFromPos(ErrorType.InvalidInfixOperator, pos, [lTypeErr, rType.toString()]);
						}
					}
				}
				
				return null;
			}
			case Call(op, expr, params, pos): {
				final context = new ExpressionTypingContext(op == CallOperators.Call);
				final typedExpr = getInternalTypeStacked(expr, null, context);
				if(typedExpr != null) {

					final typedParams: Array<TypedExpression> = [];
					if(context.prependedArgs != null) {
						for(p in context.prependedArgs) {
							typedParams.push(p);
						}
					}
					for(p in params) {
						final r = getInternalTypeStacked(p);
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
				var result = isUntyped ? Type.Any() : Type.fromLiteral(literal, parser.scope, thisType);
				if(result != null) {
					final incrementCall = context != null && context.incrementCall;
					var replacement: Null<Literal> = null;
					var varName: Null<String> = null;
					switch(result.type) {
						case UnknownNamed(name): {
							varName = name;
							if(accessor == null) {
								final member = parser.scope.findMember(name);
								if(member != null) {
									member.onMemberUsed(parser);
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
										case ScopeMemberType.GetSet(getsetMember): {
											replacement = GetSet(getsetMember.get());
										}
										default: {}
									}
								} else {
									result = null;
								}
							} else {
								final member = parser.scope.findModifyFunction(accessor.getType(), name);
								if(member != null) {
									member.onMemberUsed(parser);
									result = member.getType();
									var isGetSet = 0;
									switch(member.type) {
										case ScopeMemberType.Function(funcMember): {
											replacement = Function(funcMember.get());
											if(incrementCall) {
												funcMember.get().incrementCallCount();
											}
										}
										case ScopeMemberType.GetSet(getsetMember): {
											isGetSet = 1;
											if(!isInterpret) {
												if(isAssignment()) {
													final setFunc = getsetMember.get().set;
													if(setFunc != null) {
														replacement = Function(setFunc);
														isGetSet = 2;
													}
												} else {
													final getFunc = getsetMember.get().get;
													if(getFunc != null) {
														replacement = Function(getFunc);
														isGetSet = 3;
													}
												}
											} else {
												replacement = GetSet(getsetMember.get());
											}
										}
										default: {}
									}

									if(!isInterpret && replacement != null && context != null) {
										context.setIsStaticExtension();

										if(isGetSet != 0 && result != null) {
											if(isGetSet == 2) convertAssignmentToArgument = true;
											parser.onTypeUsed(result);
											final internalResult: TypedExpression = Value(replacement == null ? literal : replacement, pos, result);
											return Call(CallOperators.Call, internalResult, [accessor], pos, result);
										}
									}
								} else {
									result = accessor.getType().findAccessorMemberType(name);
								}
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
							Error.addErrorFromPos(ErrorType.UnknownMember, pos, [varName == null ? "" : varName, accessor.getType().toString()]);
							Error.addErrorFromPos(ErrorType.UnknownMember, pos, [varName == null ? "" : varName, accessor.getType().toString()]);
						}
					}
				} else if(!isPrelim) {
					switch(literal) {
						case Literal.This: {
							Error.addErrorFromPos(ErrorType.InvalidThisOrSelf, pos);
						}
						default: {
							Error.addErrorFromPos(ErrorType.InvalidValue, pos);
						}
					}
				}
			}
		}
		return null;
	}

	public static function getType(expression: Expression, parser: Parser, mode: TypingMode = Normal, isInterpret: Bool = false, accessor: Null<TypedExpression> = null, context: Null<ExpressionTypingContext> = null): Null<TypedExpression> {
		final result = new ExpressionHelper(parser, mode, isInterpret);
		return result.getInternalTypeStacked(expression, accessor, context);
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
