package ast.scope.members;

import basic.Ref;

import ast.typing.FunctionType;

import ast.scope.ScopeMemberCollection;

class FunctionMember {
	public var name(default, null): String;
	public var type(default, null): Ref<FunctionType>;
	public var callCount(default, null): Int;

	public var members(default, null): Array<ScopeMember>;

	var ref: Null<Ref<FunctionMember>>;

	public function new(name: String, type: Ref<FunctionType>) {
		this.name = name;
		this.type = type;
		callCount = 0;
		members = [];
	}

	public function addMember(member: ExpressionMember) {
		members.push(Expression(member));
	}

	public function setAllMembers(members: ScopeMemberCollection) {
		this.members = members.members;
	}

	public function getRef(): Ref<FunctionMember> {
		if(ref == null) {
			ref = new Ref<FunctionMember>(this);
		}
		return ref;
	}

	public function incrementCallCount() {
		callCount++;
	}
}
