package parsers.expr;

import ast.typing.Type;

import parsers.expr.Expression;
import parsers.expr.Expression.ExpressionHelper;
import parsers.expr.Operator;

class CallOperator extends Operator {
	public var endOp(default, null): String;

	public function new(op: String, endOp: String, priority: Int, name: String, type: OperatorTranspilibilty) {
		super(op, priority, name, type);
		this.endOp = endOp;
	}

	public override function checkIfNext(parser: Parser): Bool {
		return parser.checkAhead(op + endOp);
	}

	public override function operatorLength(): Int {
		return (op + endOp).length;
	}

	public override function operatorType(): String {
		return "call";
	}

	public override function requiredArgumentLength(): Int {
		return -1;
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
			case TypeSelf(type): {
				type;
			}
			case String: {
				if(op == "[") {
					type;
				} else {
					null;
				}
			}
			case List(t): {
				if(op == "[") {
					t;
				} else {
					null;
				}
			}
			default: null;
		}

		return defaultsTest;
	}
}

enum abstract CallOperators(CallOperator) from CallOperator to CallOperator {
	public static var Call = new CallOperator("(", ")", 0xf000, "call", CppOperatorOverload);
	public static var ArrayAccess = new CallOperator("[", "]", 0xf000, "arrayAccess", CppOperatorOverloadWithOneArg);
	public static var SquiggleAccess = new CallOperator("{", "}", 0xf000, "squiggleAccess", ToFunction);

	public static function all(): Array<CallOperator> {
		return [Call, ArrayAccess, SquiggleAccess];
	}
}
