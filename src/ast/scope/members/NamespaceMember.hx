package ast.scope.members;

import basic.Ref;

import ast.typing.FunctionType;

import parsers.modules.Module;

class NamespaceMember {
	public var name(default, null): String;
	public var members(default, null): ScopeMemberCollection;

	var ref: Null<Ref<NamespaceMember>>;

	public function new(name: String) {
		this.name = name;
		members = new ScopeMemberCollection();
	}

	public function add(member: ScopeMember) {
		members.add(member);
	}

	public function getRef(): Ref<NamespaceMember> {
		if(ref == null) {
			ref = new Ref<NamespaceMember>(this);
		}
		return ref;
	}
}
