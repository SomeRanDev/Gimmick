package parsers.expr;

import parsers.expr.Expression;
import parsers.expr.Expression.ExpressionHelper;
import parsers.expr.Operator;

class PrefixOperator extends Operator {
	public function toCpp(expr: Expression) {
		return op + ExpressionHelper.toCpp(expr);
	}
}

enum abstract PrefixOperators(PrefixOperator) from PrefixOperator to PrefixOperator {
	static var Plus = new PrefixOperator("+", 0xe000);
	static var Minus = new PrefixOperator("-", 0xe000);
	static var Not = new PrefixOperator("!", 0xe000);
	static var BitNot = new PrefixOperator("~", 0xe000);
	static var Increment = new PrefixOperator("++", 0xe000);
	static var Decrement = new PrefixOperator("--", 0xe000);
	static var Dereference = new PrefixOperator("*", 0xe000);
	static var Address = new PrefixOperator("&", 0xe000);

	public static function all(): Array<PrefixOperator> {
		return [Plus, Minus, Not, BitNot, Increment, Decrement, Dereference, Address];
	}
}
