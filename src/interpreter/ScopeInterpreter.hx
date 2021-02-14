package interpreter;

import interpreter.RuntimeScope;
import interpreter.ScopeInterpreterResult;
import interpreter.ExpressionInterpreter;
using interpreter.Variant;
import interpreter.Variant.VariantHelper;

import ast.scope.ScopeMember;
import ast.scope.ExpressionMember;

import parsers.error.Error;
import parsers.error.ErrorType;
import parsers.expr.QuantumExpression;

class ScopeInterpreter {
	public static function interpret(members: Array<ScopeMember>, data: RuntimeScope): Null<ScopeInterpreterResult> {
		final result = new ScopeInterpreterResult();
		for(m in members) {
			final val = interpretScope(m, data);
			if(val != null) {
				result.setValue(val);
				return result;
			}
		}
		return null;
	}

	public static function interpretScope(member: ScopeMember, data: RuntimeScope): Null<Variant> {
		switch(member.type) {
			case Variable(variable): {
				final vari = variable.get();
				final expr = vari.expression;
				var result: Null<Variant> = null;
				if(expr != null) {
					result = ExpressionInterpreter.interpret(expr, data);
				} else {
					result = VariantHelper.typeToVariantDefault(vari.type);
				}
				if(result != null) {
					data.add(vari.name, result);
				}
				//VariantHelper.typeToVariantDefault
			}
			case Expression(expr): {
				switch(expr.type) {
					case Basic(expr): {
						ExpressionInterpreter.interpret(expr, data);
					}
					case Pass: {
					}
					case Break: {
					}
					case Continue: {
					}
					case Scope(subExpressions/*: Array<ScopeMember>*/): {
						final result = interpret(subExpressions, data);
						if(result.returnValue != null) {
							return result.returnValue;
						}
					}
					case IfStatement(expr, subExpressions, checkTrue): {
						final cond = getBoolFromExpr(expr, data);
						if(cond == null) return null;
						if(cond.toBool() == checkTrue) {
							final result = interpretSubExpressions(subExpressions, data);
							if(result != null) return result;
						}
					}
					case IfElseStatement(ifState, elseExpressions): {
						var performElse = false;
						switch(ifState.type) {
							case IfStatement(expr, subExpressions, checkTrue): {
								final cond = getBoolFromExpr(expr, data);
								if(cond == null) return null;
								if(cond.toBool() == checkTrue) {
									final result = interpretSubExpressions(subExpressions, data);
									if(result != null) return result;
								} else {
									performElse = true;
								}
							}
							default: {}
						}
						if(performElse) {
							final result = interpretSubExpressions(elseExpressions, data);
							if(result != null) return result;
						}
					}
					case IfElseIfChain(ifStatements, elseExpressions): {
						var performElse = true;
						for(statement in ifStatements) {
							switch(statement.type) {
								case IfStatement(expr, subExpressions, checkTrue): {
									final cond = getBoolFromExpr(expr, data);
									if(cond == null) return null;
									if(cond.toBool() == checkTrue) {
										performElse = false;
										final result = interpretSubExpressions(subExpressions, data);
										if(result != null) return result;
										break;
									}
								}
								default: {}
							}
						}
						if(performElse) {
							final result = interpretSubExpressions(elseExpressions, data);
							if(result != null) return result;
						}
					}
					case Loop(expr/*: Null<QuantumExpression>*/, subExpressions/*: Array<ScopeMember>*/, checkTrue/*: Bool*/): {

					}
					case ReturnStatement(expr/*: QuantumExpression*/): {
						return ExpressionInterpreter.interpret(expr, data);
					}
				}
			}
			default: {}
		}
		return null;
	}

	public static function getBoolFromExpr(expr: QuantumExpression, data: RuntimeScope): Null<Variant> {
		final cond = ExpressionInterpreter.interpret(expr, data);
		if(cond == null || !cond.isBool()) {
			Error.addErrorFromPos(ErrorType.InterpreterMustReturnBool, expr.getPosition(), [cond == null ? "null" : cond.typeString()]);
			return null;
		}
		return cond;
	}

	public static function interpretSubExpressions(subExpressions: Array<ScopeMember>, data: RuntimeScope): Null<Variant> {
		final result = interpret(subExpressions, data);
		return result.returnValue;
	}
}
