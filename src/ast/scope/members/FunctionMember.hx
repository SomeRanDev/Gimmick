package ast.scope.members;

import basic.Ref;

import ast.typing.FunctionType;

import ast.scope.ScopeMemberCollection;
import ast.scope.members.MemberLocation;
import ast.scope.members.FunctionOption;

class FunctionMember {
	public var name(default, null): String;
	public var type(default, null): Ref<FunctionType>;
	public var memberLocation(default, null): MemberLocation;
	public var callCount(default, null): Int;

	public var options(default, null): Array<FunctionOption>;
	public var members(default, null): Array<ScopeMember>;

	var ref: Null<Ref<FunctionMember>>;

	public function new(name: String, type: Ref<FunctionType>, memberLocation: MemberLocation, options: Array<FunctionOption>) {
		this.name = name;
		this.type = type;
		this.memberLocation = memberLocation;
		this.options = options;
		callCount = 0;
		members = [];
	}

	public function addMember(member: ScopeMember) {
		members.push(member);
	}

	public function setAllMembers(members: ScopeMemberCollection) {
		this.members = members.members;
	}

	public function getNamespaces(): Null<Array<String>> {
		return switch(memberLocation) {
			case TopLevel(namespaces): namespaces;
			default: null;
		}
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

	public function isInject() {
		return options.contains(Inject);
	}
}
