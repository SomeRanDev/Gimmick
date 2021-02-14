package parsers.typing;

import ast.scope.ScopeMember;
import ast.scope.ExpressionMember;
import ast.scope.ScopeMemberCollection;

import ast.typing.Type;

import parsers.Parser;
import parsers.error.Error;
import parsers.error.ErrorType;
using parsers.expr.QuantumExpression;
import parsers.expr.Position;

class ReturnSweepContext {
	public var expectedType(default, null): Null<Type>;
	public var expectedTypeKnown(default, null): Bool;
	public var initialTypeFound(default, null): Null<Position>;

	public function new(expectedType: Null<Type>) {
		this.expectedType = expectedType;
		expectedTypeKnown = expectedType != null;
		initialTypeFound = expectedType != null ? expectedType.position : null;
	}

	public function onReturnFound(returnType: Null<Type>, position: Position) {
		if(expectedTypeKnown) {
			if(expectedType != null && returnType != null) {
				var err = expectedType.canBePassed(returnType);
				if(err != null) {
					if(err == ErrorType.CannotAssignThisTypeToThatType) {
						err = ErrorType.ReturnedTypeDoesNotMatchReturnType;
					}
					Error.addErrorFromPos(err, position, [returnType.toString(), expectedType.toString()]);
				}
			} else if(expectedType != null) {
				Error.addErrorFromPos(ErrorType.ReturnExpressionExpected, position, [expectedType.toString()]);
			} else if(returnType != null) {
				Error.addErrorFromPos(ErrorType.NoReturnExpressionExpected, position);
			}
		} else {
			expectedTypeKnown = true;
			expectedType = returnType;
			initialTypeFound = position;
		}
	}

	public static function findReturnStatement(expr: ExpressionMember, context: ReturnSweepContext): Bool {
		switch(expr.type) {
			case ReturnStatement(e): {
				var pos = e == null ? expr.wordPosition : expr.position;
				context.onReturnFound(e == null ? null : e.getType(), pos == null ? expr.position : pos);
				return true;
			}
			case Scope(exprs): return findReturnStatementFromMembers(exprs, context);
			case IfElseStatement(ifState, elseExpressions): {
				var ifHasReturn = false;
				switch(ifState.type) {
					case IfStatement(_, exprs, _): {
						ifHasReturn = findReturnStatementFromMembers(exprs, context);
					}
					default: {}
				}
				return ifHasReturn && findReturnStatementFromMembers(elseExpressions, context);
			}
			case IfElseIfChain(ifStatements, elseExpressions): {
				var allIfsHaveReturn = true;
				for(ifState in ifStatements) {
					switch(ifState.type) {
						case IfStatement(_, exprs, _): {
							if(!findReturnStatementFromMembers(exprs, context)) {
								allIfsHaveReturn = false;
							}
						}
						default: {}
					}
				}
				return allIfsHaveReturn && (elseExpressions == null ? false : findReturnStatementFromMembers(elseExpressions, context));
			}
			default: {}
		}
		return false;
	}

	public static function findReturnStatementFromMembers(exprList: Array<ScopeMember>, context: ReturnSweepContext): Bool {
		for(e in exprList) {
			switch(e.type) {
				case Expression(expr): {
					if(findReturnStatement(expr, context)) {
						return true;
					}
				}
				default: {}
			}
		}
		return false;
	}
}
