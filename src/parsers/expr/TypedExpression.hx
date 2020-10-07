package parsers.expr;

import ast.typing.Type;

import parsers.expr.Literal;
import parsers.expr.PrefixOperator;
import parsers.expr.SuffixOperator;
import parsers.expr.InfixOperator;

enum TypedExpression {
	Prefix(op: PrefixOperator, expr: TypedExpression, pos: Position, type: Type);
	Suffix(op: SuffixOperator, expr: TypedExpression, pos: Position, type: Type);
	Infix(op: InfixOperator, lexpr: TypedExpression, rexpr: TypedExpression, pos: Position, type: Type);
	Value(literal: Literal, pos: Position, type: Type);
}

class TypedExpressionHelper {
	public static function getType(typeExpr: TypedExpression): Type {
		switch(typeExpr) {
			case Prefix(_, _, _, type): return type;
			case Suffix(_, _, _, type): return type;
			case Infix(_, _, _, _, type): return type;
			case Value(_, _, type): return type;
		}
	}
}
