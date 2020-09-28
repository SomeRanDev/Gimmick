package parsers.expr;

import parsers.expr.Expression;
import parsers.expr.Expression.ExpressionHelper;
import parsers.expr.Operator;

class SuffixOperator extends Operator {
	public function toCpp(expr: Expression) {
		return ExpressionHelper.toCpp(expr) + op;
	}
}

enum abstract SuffixOperators(SuffixOperator) from SuffixOperator to SuffixOperator {
	static var Increment = new SuffixOperator("++", 0xf000);
	static var Decrement = new SuffixOperator("--", 0xf000);

	public static function all(): Array<SuffixOperator> {
		return [Increment, Decrement];
	}
}
