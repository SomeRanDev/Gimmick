package interpreter;

import interpreter.RuntimeScope;
import interpreter.ScopeInterpreterResult;
import interpreter.ExpressionInterpreter;
using interpreter.Variant;
import interpreter.Variant.VariantHelper;

import ast.scope.ScopeMember;

import parsers.Error;
import parsers.ErrorType;

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
				//VariantHelper.typeToVariantDefault
			}
			case Expression(expr): {
				switch(expr) {
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
						final cond = ExpressionInterpreter.interpret(expr, data);
						if(cond == null || !cond.isBool()) {
							Error.addErrorFromPos(ErrorType.InterpreterMustReturnBool, expr.getPosition());
							return null;
						}
						if(cond.toBool() == checkTrue) {
							final result = interpret(subExpressions, data);
							if(result.returnValue != null) {
								return result.returnValue;
							}
						}
					}
					case IfElseStatement(ifState/*: ExpressionMember*/, elseExpressions/*: Array<ScopeMember>*/): {

					}
					case IfElseIfChain(ifStatements/*: Array<ExpressionMember>*/, elseExpressions/*: Null<Array<ScopeMember>>*/): {

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
}
