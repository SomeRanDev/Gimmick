package interpreter;

import haxe.ds.GenericStack;

import interpreter.Variant;

class RuntimeScope {
	public var stack(default, null): GenericStack<Map<String,Variant>>;

	public function new() {
		stack = new GenericStack();
		stack.add([]);
	}

	public static function fromMap(map: Map<String,Variant>): RuntimeScope {
		final scope = new RuntimeScope();
		for(key in map.keys()) {
			final val = map.get(key);
			if(val != null) {
				scope.add(key, val);
			}
		}
		scope.push();
		return scope;
	}

	public function add(name: String, value: Variant) {
		final first = stack.first();
		if(first != null) {
			first[name] = value;
		}
	}

	public function find(name: String): Null<Variant> {
		for(s in stack) {
			if(s.exists(name)) {
				return s.get(name);
			}
		}
		return null;
	}

	public function push() {
		stack.add([]);
	}

	public function pop(): Null<Map<String,Variant>> {
		return stack.pop();
	}
}
