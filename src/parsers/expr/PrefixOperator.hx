package parsers.expr;

import ast.typing.Type;

import parsers.expr.Expression;
import parsers.expr.Expression.ExpressionHelper;
import parsers.expr.Operator;

class PrefixOperator extends Operator {
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

		if(op == "*") {
			return Type.Pointer(type);
		}
		if(op == "&") {
			switch(type.type) {
				case Reference(internalType): {
					return internalType;
				}
				default: {}
			}
		}

		if(op == "!") {
			switch(type.type) {
				case Boolean: {
					return type;
				}
				default: {}
			}
		}

		if(op != "!") {
			switch(type.type) {
				case Number(_): return type;
				default: {}
			}
		}

		return null;
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
