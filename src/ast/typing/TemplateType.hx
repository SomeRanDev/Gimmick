package ast.typing;

import basic.Ref;

import ast.scope.Scope;
import ast.scope.ScopeMember;
import ast.scope.members.ClassMember;

import ast.typing.ClassType;
import ast.typing.TemplateArgument;
import ast.typing.TemplateArgumentRequirement;

class TemplateType {
	public var name: String;
	public var restrictions: Null<Array<TemplateArgumentRequirement>>;

	public function new(name: String, restrictions: Null<Array<TemplateArgumentRequirement>>) {
		this.name = name;
		this.restrictions = restrictions;
	}

	public function toClassMember(name: String, scope: Scope): ClassMember {
		final extendList: Array<Type> = [];
		final members: Array<ScopeMember> = [];
		if(restrictions != null) {
			for(r in restrictions) {
				final e = r.isExtends();
				if(e != null) {
					final clsType = e.isClassType();
					if(clsType != null) {
						extendList.push(e);
					}
				} else {
					final mem = r.toMember();
					if(mem != null) {
						members.push(mem);
					}
				}
			}
		}
		final clsType = new ClassType(name, extendList.length == 0 ? null : extendList);
		clsType.members.setAllMembers(members);
		return new ClassMember(name, clsType.getRef(), TopLevel(null), [ Extern ]);
	}
}
