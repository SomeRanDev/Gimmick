package parsers.expr;

import ast.typing.Type;

using parsers.expr.Literal;
import parsers.expr.PrefixOperator;
import parsers.expr.SuffixOperator;
import parsers.expr.InfixOperator;

enum TypedExpression {
	Prefix(op: PrefixOperator, expr: TypedExpression, pos: Position, type: Type);
	Suffix(op: SuffixOperator, expr: TypedExpression, pos: Position, type: Type);
	Infix(op: InfixOperator, lexpr: TypedExpression, rexpr: TypedExpression, pos: Position, type: Type);
	Call(op: CallOperator, expr: TypedExpression, params: Array<TypedExpression>, pos: Position, type: Type);
	Value(literal: Literal, pos: Position, type: Type);
}

class TypedExpressionHelper {
	public static function getType(typeExpr: TypedExpression): Type {
		switch(typeExpr) {
			case Prefix(_, _, _, type): return type;
			case Suffix(_, _, _, type): return type;
			case Infix(_, _, _, _, type): return type;
			case Call(_, _, _, _, type): return type;
			case Value(_, _, type): return type;
		}
	}

	public static function isConst(typeExpr: TypedExpression): Bool {
		return switch(typeExpr) {
			case Prefix(_, e, _, _): isConst(e);
			case Suffix(_, e, _, _): isConst(e);
			case Infix(_, le, re, _, _): isConst(le) && isConst(re);
			case Call(_, e, _, _, _): false;
			case Value(l, _, _): l.isConst();
		}
	}

	public static function getPosition(expr: TypedExpression): Position {
		return switch(expr) {
			case Prefix(_, _, pos, _): pos;
			case Suffix(_, _, pos, _): pos;
			case Infix(_, _, _, pos, _): pos;
			case Value(_, pos, _): pos;
			case Call(_, _, _, pos, _): pos;
		};
	}
}
