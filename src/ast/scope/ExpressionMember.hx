package ast.scope;

import ast.typing.Type;

import parsers.expr.TypedExpression;

enum ExpressionMember {
	Basic(expr: TypedExpression);
	IfStatement(expr: TypedExpression, subExpressions: Array<ExpressionMember>, checkTrue: Bool);
	ReturnStatement(expr: TypedExpression);
}
