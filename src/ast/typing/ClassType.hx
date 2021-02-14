package ast.typing;

import basic.Ref;

import parsers.expr.TypedExpression;

import ast.scope.ScopeMember;
import ast.scope.ScopeMemberCollection;
import ast.scope.members.ClassMember;

import ast.typing.TemplateArgument;

class ClassType {
	public var member(default, null): Null<ClassMember>;
	public var name(default, null): String;
	public var parent(default, null): Null<Ref<ClassType>>;
	public var members(default, null): ScopeMemberCollection;
	public var templateArguments(default, null): Null<Array<TemplateArgument>>;
	public var extendedTypes(default, null): Null<Array<Type>>;

	var ref: Null<Ref<ClassType>>;

	public function new(name: String, parent: Null<Ref<ClassType>>) {
		this.name = name;
		this.parent = parent;
		members = new ScopeMemberCollection();
	}

	public function setMember(member: ClassMember) {
		this.member = member;
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

	public function findConstructorWithParameters(params: Array<Type>): Null<Array<ScopeMember>> {
		return members.findConstructorWithParameters(params);
	}

	public function hasAttribute(attributeName: String): Bool {
		if(member != null && member.scopeMember != null) {
			return member.scopeMember.hasAttribute(attributeName);
		}
		return false;
	}

	public function extendsFrom(type: Type): Bool {
		if(extendedTypes != null) {
			for(t in extendedTypes) {
				if(t.equals(type)) {
					return true;
				}
			}
		}
		return false;
	}
}
