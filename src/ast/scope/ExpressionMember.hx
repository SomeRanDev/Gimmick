package ast.scope;

import ast.scope.ScopeMember;
import ast.typing.Type;

import parsers.expr.Position;
import parsers.expr.TypedExpression;
import parsers.expr.QuantumExpression;

enum ExpressionMemberType {
	Basic(expr: QuantumExpression);
	Pass;
	Break;
	Continue;
	Scope(subExpressions: Array<ScopeMember>);
	IfStatement(expr: QuantumExpression, subExpressions: Array<ScopeMember>, checkTrue: Bool);
	IfElseStatement(ifStatement: ExpressionMember, elseExpressions: Array<ScopeMember>);
	IfElseIfChain(ifStatements: Array<ExpressionMember>, elseExpressions: Null<Array<ScopeMember>>);
	Loop(expr: Null<QuantumExpression>, subExpressions: Array<ScopeMember>, checkTrue: Bool);
	ReturnStatement(expr: Null<QuantumExpression>);
}

class ExpressionMember {
	public var type(default, null): ExpressionMemberType;
	public var position(default, null): Position;
	public var wordPosition(default, null): Null<Position>;

	public function new(type: ExpressionMemberType, position: Position, wordPosition: Null<Position> = null) {
		this.type = type;
		this.position = position;
		this.wordPosition = wordPosition;
	}
}

class ExpressionMemberHelper {
	public static function isReturn(expr: ExpressionMember): Bool {
		switch(expr.type) {
			case ReturnStatement(_): return true;
			case Scope(exprs): return hasReturn(exprs);
			case IfElseStatement(ifState, elseExpressions): {
				var ifHasReturn = false;
				switch(ifState.type) {
					case IfStatement(_, exprs, _): {
						if(!hasReturn(exprs)) {
							return false;
						}
					}
					default: {}
				}
				return hasReturn(elseExpressions);
			}
			case IfElseIfChain(ifStatements, elseExpressions): {
				for(ifState in ifStatements) {
					switch(ifState.type) {
						case IfStatement(_, exprs, _): {
							if(!hasReturn(exprs)) {
								return false;
							}
						}
						default: {}
					}
				}
				return elseExpressions == null ? true : hasReturn(elseExpressions);
			}
			default: {}
		}
		return false;
	}

	public static function hasReturn(exprList: Array<ScopeMember>): Bool {
		for(e in exprList) {
			switch(e.type) {
				case Expression(expr): {
					if(isReturn(expr)) {
						return true;
					}
				}
				default: {}
			}
		}
		return false;
	}

	public static function isPass(expr: ExpressionMember): Bool {
		switch(expr.type) {
			case Pass: return true;
			default: {}
		}
		return false;
	}
}
