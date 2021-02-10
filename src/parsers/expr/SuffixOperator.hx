package parsers.expr;

import ast.typing.Type;

using ast.scope.ScopeMember;

import parsers.expr.Expression;
import parsers.expr.Expression.ExpressionHelper;
import parsers.expr.Operator;

class SuffixOperator extends Operator {
	public override function operatorType(): String {
		return "suffix";
	}

	public override function requiredArgumentLength(): Int {
		return 0;
	}

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

		final overloadOp = type.findOverloadedSuffixOperator(this);
		if(overloadOp != null) {
			switch(overloadOp.type) {
				case ScopeMemberType.SuffixOperator(_, func): {
					return func.get().type.get().returnType;
				}
				default: {}
			}
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
	public static var Increment = new SuffixOperator("++", 0xf000, "increment", ToFunction);
	public static var Decrement = new SuffixOperator("--", 0xf000, "decrement", ToFunction);

	public static function all(): Array<SuffixOperator> {
		return [Increment, Decrement];
	}
}
