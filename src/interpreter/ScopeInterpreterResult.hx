package interpreter;

import interpreter.Variant;

class ScopeInterpreterResult {
	public var returnValue(default, null): Null<Variant>;
	public var membersInterpreted(default, null): Int;

	public function new() {
		returnValue = null;
		membersInterpreted = 0;
	}

	public function incrementMembers() {
		membersInterpreted++;
	}

	public function setValue(v: Variant) {
		returnValue = v;
	}
}
