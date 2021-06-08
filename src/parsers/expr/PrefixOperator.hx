package parsers.expr;

import ast.typing.Type;

using ast.scope.ScopeMember;

import parsers.expr.Expression;
import parsers.expr.Expression.ExpressionHelper;
import parsers.expr.Operator;

class PrefixOperator extends Operator {
	public override function operatorType(): String {
		return "prefix";
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

		final overloadOp = type.findOverloadedPrefixOperator(this);
		if(overloadOp != null) {
			switch(overloadOp.type) {
				case ScopeMemberType.PrefixOperator(_, func): {
					return func.get().type.get().returnType;
				}
				default: {}
			}
		}
		// do overloaded stuff

		if(op == "*") {
			switch(type.type) {
				case Pointer(t): {
					return t;
				}
				default: {}
			}
		}
		if(op == "&") {
			switch(type.type) {
				case Reference(internalType): {
					return Type.Pointer(internalType);
				}
				default: {
					return Type.Pointer(type);
				}
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
	public static var Plus = new PrefixOperator("+", 0xe000, "plus", CppOperatorOverload);
	public static var Minus = new PrefixOperator("-", 0xe000, "minus", CppOperatorOverload);
	public static var Not = new PrefixOperator("!", 0xe000, "logicNot", CppOperatorOverload);
	public static var BitNot = new PrefixOperator("~", 0xe000, "bitNot", CppOperatorOverload);
	public static var Increment = new PrefixOperator("++", 0xe000, "preIncrement", CppOperatorOverload);
	public static var Decrement = new PrefixOperator("--", 0xe000, "preDecrement", CppOperatorOverload);
	public static var Dereference = new PrefixOperator("*", 0xe000, "dereference", CppOperatorOverload);
	public static var Address = new PrefixOperator("&", 0xe000, "address", CppOperatorOverload);

	public static function all(): Array<PrefixOperator> {
		return [Plus, Minus, Not, BitNot, Increment, Decrement, Dereference, Address];
	}
}
