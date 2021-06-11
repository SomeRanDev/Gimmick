package parsers.expr;

import haxe.macro.Type.TypedExpr;
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
		final type = switch(typeExpr) {
			case Prefix(_, _, _, t): t;
			case Suffix(_, _, _, t): t;
			case Infix(_, _, _, _, t): t;
			case Call(_, _, _, _, t): t;
			case Value(_, _, t): t;
		}
		return type.applyTypeArguments();
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
		}
	}

	public static function getFullPosition(expr: TypedExpression): Position {
		return switch(expr) {
			case Prefix(_, e, _, _): getPosition(expr).merge(getFullPosition(e));
			case Suffix(_, e, _, _): getPosition(expr).merge(getFullPosition(e));
			case Infix(_, le, re, _, _): getPosition(expr).merge(getFullPosition(le), getFullPosition(re));
			case Call(_, e, _, _, _): getPosition(expr).merge(getFullPosition(e));
			case Value(_, _, _): getPosition(expr);
		}
	}

	public static function discoverVariableType(expr: TypedExpression, type: Type): Null<TypedExpression> {
		switch(expr) {
			case Value(literal, pos, _): {
				switch(literal) {
					case Variable(member): {
						if(member.discoverType(type)) {
							return Value(literal, pos, type);
						}
					}
					default: {}
				}
			}
			default: {}
		}
		return null;
	}

	public static function convertToAlloc(expr: Null<TypedExpression>, hasCall: Bool): Null<TypedExpression> {
		if(expr != null) {
			switch(expr) {
				case Value(literal, pos, type): {
					final typeSelfType = type.isTypeSelf();
					final allocedType = type.convertToAlloc();
					if(typeSelfType != null && allocedType != null) {
						return Value(Literal.TypeName(allocedType), pos, hasCall ? allocedType : Type.Pointer(typeSelfType));
					}
				}
				default: {}
			}
		}
		return null;
	}
}
