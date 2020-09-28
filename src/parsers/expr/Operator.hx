package parsers.expr;

import parsers.expr.Expression;

class Operator {
	public var op(default, null): String;
	public var priority(default, null): Int;

	public function new(op: String, priority: Int) {
		this.op = op;
		this.priority = priority;
	}
}
