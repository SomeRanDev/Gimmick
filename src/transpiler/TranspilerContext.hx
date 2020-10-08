package transpiler;

import haxe.ds.GenericStack;

class TranspilerContext {
	var namespaceStack: GenericStack<String>;

	public function new() {
		namespaceStack = new GenericStack();
	}

	public function pushNamespace(namespace: String) {
		namespaceStack.add(namespace);
	}

	public function popNamespace() {
		namespaceStack.pop();
	}

	public function matchesNamespace(namespaces: Null<Array<String>>): Bool {
		if(namespaces == null) {
			return namespaceStack.isEmpty();
		} else if(namespaceStack.isEmpty()) {
			return namespaces.length == 0;
		}
		var index = 0;
		for(n in namespaceStack) {
			if(index > namespaces.length || n != namespaces[index]) {
				return false;
			}
			index++;
		}
		return true;
	}
}
