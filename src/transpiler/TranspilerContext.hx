package transpiler;

import haxe.ds.GenericStack;

import parsers.expr.TypedExpression;

import interpreter.Variant;

using transpiler.Language;

enum OutputContext {
	TopLevel;
	Function;
	Class;
}

class TranspilerContext {
	var namespaceStack: GenericStack<String>;
	var language: Language;
	var context: GenericStack<OutputContext>;
	var values: Map<String, Variant>;
	var thisExprStack: GenericStack<TypedExpression>;
	var namedVarReplacements: GenericStack<Map<String, TypedExpression>>;

	public function new(language: Language) {
		namespaceStack = new GenericStack();
		context = new GenericStack();
		thisExprStack = new GenericStack();
		namedVarReplacements = new GenericStack();
		this.language = language;
		values = [];
		values.set("cpp", Bool(isCpp()));
		values.set("js", Bool(isJs()));
	}

	public function isCpp(): Bool {
		return language.isCpp();
	}

	public function isJs(): Bool {
		return language.isJs();
	}

	public function getValues(): Map<String, Variant> {
		return values;
	}

	public function getContext(): OutputContext {
		final result = context.first();
		return result == null ? TopLevel : result;
	}

	public function pushContext(c: OutputContext) {
		context.add(c);
	}

	public function popContext(c: OutputContext) {
		context.add(c);
	}

	public function isTopLevel(): Bool {
		return switch(getContext()) {
			case TopLevel: true;
			default: false;
		}
	}

	public function hasNamespace(): Bool {
		return !namespaceStack.isEmpty();
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

	public function reverseJoinArray(arr: Array<String>, attachment: String) {
		final temp = arr.copy();
		temp.reverse();
		return temp.join(attachment);
	}

	public function constructNamespace(separator: String = "."): String {
		final result = [];
		for(n in namespaceStack) {
			result.push(n);
		}
		return reverseJoinArray(result, separator);
	}

	public function pushThisExpr(expr: TypedExpression) {
		thisExprStack.add(expr);
	}

	public function popThisExpr() {
		thisExprStack.pop();
	}

	public function thisExpr(): Null<TypedExpression> {
		return thisExprStack.first();
	}

	public function pushVarReplacements() {
		namedVarReplacements.add([]);
	}

	public function popVarReplacements() {
		namedVarReplacements.pop();
	}

	public function addVarReplacement(name: String, expr: TypedExpression) {
		final first = namedVarReplacements.first();
		if(first != null) {
			first[name] = expr;
		}
	}

	public function findVarReplacement(name: String): Null<TypedExpression> {
		final first = namedVarReplacements.first();
		if(first != null) {
			return first[name];
		}
		return null;
	}
}
