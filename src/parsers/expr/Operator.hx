package parsers.expr;

import parsers.Parser;
import parsers.expr.Expression;

enum OperatorTranspilibilty {
	CppOperatorOverload;
	CppOperatorOverloadWithOneArg;
	ToFunction;
	ToAccessFunction;
}

class Operator {
	public var op(default, null): String;
	public var priority(default, null): Int;
	public var name(default, null): String;
	public var type(default, null): OperatorTranspilibilty;

	public function new(op: String, priority: Int, name: String, type: OperatorTranspilibilty) {
		this.op = op;
		this.priority = priority;
		this.name = name;
		this.type = type;
	}

	public function checkIfNext(parser: Parser): Bool {
		return parser.checkAhead(op);
	}

	public function toString() {
		return op + " Operator";
	}

	public function operatorLength(): Int {
		return op.length;
	}

	public function operatorType(): String {
		return "";
	}

	public function requiredArgumentLength(): Int {
		return 0;
	}
}
