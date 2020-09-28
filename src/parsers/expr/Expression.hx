package parsers.expr;

import parsers.expr.Literal;
import parsers.expr.Operator;
import parsers.expr.PrefixOperator;
import parsers.expr.SuffixOperator;
import parsers.expr.InfixOperator;

enum Expression {
	Prefix(op: PrefixOperator, expr: Expression);
	Suffix(op: SuffixOperator, expr: Expression);
	Infix(op: InfixOperator, lexpr: Expression, rexpr: Expression);
	Value(literal: Literal);
}

class ExpressionHelper {
	public static function toCpp(expression: Expression) {
		switch(expression) {
			case Prefix(op, expr): {
				return op.toCpp(expr);
			}
			case Suffix(op, expr): {
				return op.toCpp(expr);
			}
			case Infix(op, lexpr, rexpr): {
				return op.toCpp(lexpr, rexpr);
			}
			case Value(literal): {
				return "Value";
			}
		}
	}
}
