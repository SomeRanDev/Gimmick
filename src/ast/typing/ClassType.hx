package ast.typing;

import basic.Ref;

import ast.scope.ScopeMember;
import ast.scope.ScopeMemberCollection;

import ast.typing.TemplateArgument;

class ClassType {
	public var name(default, null): String;
	public var parent(default, null): Null<Ref<ClassType>>;
	public var members(default, null): ScopeMemberCollection;
	public var templateArguments(default, null): Null<Array<TemplateArgument>>;

	var ref: Null<Ref<ClassType>>;

	public function new(name: String, parent: Null<Ref<ClassType>>) {
		this.name = name;
		this.parent = parent;
		members = new ScopeMemberCollection();
	}

	public function getRef(): Ref<ClassType> {
		if(ref == null) {
			ref = new Ref<ClassType>(this);
		}
		return ref;
	}

	public function setAllMembers(members: ScopeMemberCollection) {
		this.members = members;
	}

	public function setTemplateArguments(args: Null<Array<TemplateArgument>>) {
		if(args != null) {
			templateArguments = args;
		}
	}
}
