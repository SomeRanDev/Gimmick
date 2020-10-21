package ast.scope.members;

import basic.Ref;

import ast.scope.Scope;
import ast.scope.members.FunctionMember;

class GetSetMember {
	public var name(default, null): String;
	public var get(default, null): Null<FunctionMember>;
	public var set(default, null): Null<FunctionMember>;

	var ref: Null<Ref<GetSetMember>>;

	public function new(name: String, get: Null<FunctionMember>, set: Null<FunctionMember>) {
		this.name = name;
		this.get = get;
		this.set = set;
	}

	public function getRef(): Ref<GetSetMember> {
		if(ref == null) {
			ref = new Ref<GetSetMember>(this);
		}
		return ref;
	}

	public function setGetter(get: FunctionMember) {
		this.get = get;
	}

	public function setSetter(set: FunctionMember) {
		this.set = set;
	}

	public function isGetAvailable(): Bool {
		return get == null;
	}

	public function isSetAvailable(): Bool {
		return set == null;
	}

	public static function generateFunctionName(prefix: String, originalName: String, scope: Scope): String {
		final base = prefix + originalName;
		var num = 2;
		var result = base;
		while(scope.existInCurrentScope(result) != null) {
			result = base + Std.string(num++);
		}
		return result;
	}

	public static function generateGetFunctionName(originalName: String, scope: Scope): String {
		return generateFunctionName("get_", originalName, scope);
	}

	public static function generateSetFunctionName(originalName: String, scope: Scope): String {
		return generateFunctionName("set_", originalName, scope);
	}
}
