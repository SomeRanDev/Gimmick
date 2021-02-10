package ast.typing;

import basic.Ref;

import parsers.expr.TypedExpression;

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
		for(mem in members) {
			mem.setClassType(this);
		}
	}

	public function setTemplateArguments(args: Null<Array<TemplateArgument>>) {
		if(args != null) {
			templateArguments = args;
		}
	}
	public function getAllConstructors(): Array<ScopeMember> {
		final result = [];
		for(member in members) {
			switch(member.type) {
				case Function(funcRef): {
					if(funcRef.get().isConstructor()) {
						result.push(member);
					}
				}
				default: {}
			}
		}
		return result;
	}

	public function findConstructorWithParameters(params: Array<TypedExpression>): Null<Array<ScopeMember>> {
		return members.findConstructorWithParameters(params);
	}
}
