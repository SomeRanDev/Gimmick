package ast.typing;

import basic.Ref;

import parsers.Parser;
import parsers.expr.TypedExpression;

import ast.scope.Scope;
import ast.scope.ScopeMember;
import ast.scope.ScopeMemberCollection;
import ast.scope.ScopeParameterSearchResult;
import ast.scope.members.ClassMember;

import ast.typing.TemplateArgument;

import parsers.error.Error;

class ClassType {
	public var member(default, null): Null<ClassMember>;
	public var name(default, null): String;
	public var members(default, null): ScopeMemberCollection;
	public var templateArguments(default, null): Null<Array<TemplateArgument>>;
	public var extendedTypes(default, null): Null<Array<Type>>;

	var id: Int;
	var ref: Null<Ref<ClassType>>;

	static var latestId: Int = 0;

	public function new(name: String, extendedTypes: Null<Array<Type>>) {
		this.name = name;
		this.extendedTypes = extendedTypes;
		members = new ScopeMemberCollection();
		id = latestId++;
	}

	public function equals(other: ClassType): Bool {
		return id == other.id;
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

	public function setExtendedTypes(types: Array<Type>) {
		extendedTypes = types;
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

	public function hasConstructors(): Bool {
		if(extendedTypes != null) {
			for(e in extendedTypes) {
				final clsType = e.isClassType();
				if(clsType != null) {
					if(clsType.get().members.hasConstructors()) {
						return true;
					}
				}
			}
		}
		return members.hasConstructors();
	}

	public function findConstructorWithParameters(params: Array<Type>): ScopeParameterSearchResult {
		final result = members.findConstructorWithParameters(params);
		if(result.found) {
			return result;
		}
		if(extendedTypes != null) {
			for(t in extendedTypes) {
				final clsType = t.isClassType();
				if(clsType != null) {
					final newResult = clsType.get().findConstructorWithParameters(params);
					if(newResult.found) {
						return newResult;
					}
				}
			}
		}
		if(result.error != null) {
			Error.addErrorPromise("funcWrongParam", result.error);
		}
		return result;
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

	public function applyTypeArguments(args: Array<Type>, templateArguments: Null<Array<TemplateArgument>> = null): ClassType {
		if(templateArguments == null) templateArguments = this.templateArguments;
		if(templateArguments == null) return this;
		final newParents = extendedTypes == null ? null : extendedTypes.map(e -> e.applyTypeArguments(args, templateArguments));
		final result = new ClassType(name, newParents);
		if(member != null) result.setMember(member);
		result.setAllMembers(members.map(m -> m.applyTypeArguments(args, templateArguments)));
		result.setTemplateArguments(this.templateArguments);
		result.id = id;
		return result;
	}

	public function resolveUnknownTypes(parser: Parser): Bool {
		var result = false;
		if(extendedTypes != null) {
			for(a in extendedTypes) {
				if(a.resolveUnknownNamedType(parser)) {
					result = true;
				}
			}
		}
		return result;
	}
}
