package ast.typing;

import basic.Ref;

import ast.scope.Scope;
import ast.scope.members.ClassMember;

import ast.typing.Type;
import ast.typing.FunctionType;
import ast.typing.TemplateType;
import ast.typing.TemplateArgumentRequirement;

import parsers.expr.Position;

class TemplateArgument {
	public var name: String;
	public var type: TemplateType;
	public var position: Position;
	public var defaultType: Null<Type>;

	var ref: Null<Ref<TemplateArgument>>;

	public function new(name: String, restrictions: Null<Array<TemplateArgumentRequirement>>, position: Position, defaultType: Null<Type> = null) {
		this.name = name;
		this.type = new TemplateType("", restrictions);
		this.position = position;
		this.defaultType = defaultType;
	}

	public function toClassMember(scope: Scope): ClassMember {
		return type.toClassMember(name, scope);
	}

	public function getRef(): Ref<TemplateArgument> {
		if(ref == null) {
			ref = new Ref<TemplateArgument>(this);
		}
		return ref;
	}
}
