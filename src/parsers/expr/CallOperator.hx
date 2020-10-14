package parsers.expr;

import ast.typing.Type;

import parsers.expr.Expression;
import parsers.expr.Expression.ExpressionHelper;
import parsers.expr.Operator;

class CallOperator extends Operator {
	public var endOp(default, null): String;

	public function new(op: String, endOp: String, priority: Int) {
		super(op, priority);
		this.endOp = endOp;
	}

	public function findReturnType(type: Type, params: Array<Type>): Null<Type> {
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
			case Function(func, typeParams): {
				var result = func.get().returnType;
				if(typeParams != null) {
					switch(result.type) {
						case Template(index): {
							if(index > 0 && index < typeParams.length) {
								result = typeParams[index];
							}
						}
						default: {}
					}
				}
				result;
			}
			default: null;
		}

		return defaultsTest;
	}
}

enum abstract CallOperators(CallOperator) from CallOperator to CallOperator {
	public static var Call = new CallOperator("(", ")", 0xf000);
	public static var ArrayAccess = new CallOperator("[", "]", 0xf000);
	public static var SquiggleAccess = new CallOperator("{", "}", 0xf000);

	public static function all(): Array<CallOperator> {
		return [Call, ArrayAccess, SquiggleAccess];
	}
}
