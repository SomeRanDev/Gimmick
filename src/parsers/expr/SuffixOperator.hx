package parsers.expr;

import ast.typing.Type;

import parsers.expr.Expression;
import parsers.expr.Expression.ExpressionHelper;
import parsers.expr.Operator;

class SuffixOperator extends Operator {
	public function findReturnType(type: Type): Null<Type> {
		final initialTest = switch(type.type) {
			case Void:
				Type.Void();
			case Any | External(_, _):
				Type.Any();
			default: null;
		}
		if(initialTest != null) {
			return initialTest;
		}

		// do overloaded stuff

		final defaultsTest = switch(type.type) {
			case Number(numType): type;
			default: null;
		}

		return defaultsTest;
	}
}

enum abstract SuffixOperators(SuffixOperator) from SuffixOperator to SuffixOperator {
	public static var Increment = new SuffixOperator("++", 0xf000);
	public static var Decrement = new SuffixOperator("--", 0xf000);

	public static function all(): Array<SuffixOperator> {
		return [Increment, Decrement];
	}
}
