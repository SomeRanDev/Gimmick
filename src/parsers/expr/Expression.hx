package parsers.expr;

import ast.scope.Scope;
using ast.scope.ScopeMember;
import ast.typing.Type;

import parsers.Parser;
import parsers.expr.ExpressionTyper;
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

class ExpressionHelper {
	public static function getType(expression: Expression, parser: Parser, mode: TypingMode = Normal, isInterpret: Bool = false, thisType: Null<Type> = null, accessor: Null<TypedExpression> = null, context: Null<ExpressionTypingContext> = null): Null<TypedExpression> {
		final result = new ExpressionTyper(parser, mode, isInterpret, thisType);
		return result.getInternalTypeStacked(expression, accessor, context);
	}

	public static function getPosition(expr: Expression): Position {
		return switch(expr) {
			case Prefix(_, _, pos): pos;
			case Suffix(_, _, pos): pos;
			case Infix(_, _, _, pos): pos;
			case Value(_, pos): pos;
			case Call(_, _, _, pos): pos;
		}
	}

	public static function getFullPosition(expr: Expression): Position {
		return switch(expr) {
			case Prefix(_, e, _): getPosition(expr).merge(getFullPosition(e));
			case Suffix(_, e, _): getPosition(expr).merge(getFullPosition(e));
			case Infix(_, le, re, _): getPosition(expr).merge(getFullPosition(le), getFullPosition(re));
			case Call(_, e, params, _): getPosition(expr).merge(getFullPosition(e));
			case Value(_, _): getPosition(expr);
		}
	}

	public static function getName(expr: Expression): Null<String> {
		return switch(expr) {
			case Value(literal, _): {
				switch(literal) {
					case Name(name, _): name;
					default: null;
				}
			}
			default: null;
		}
	}

	public static function isAlloc(expr: Expression): Bool {
		return getName(expr) == "alloc";
	}
}
