package ast.scope.members;

import basic.Ref;

import parsers.expr.TypedExpression;

import ast.typing.Type;

enum VariableMemberType {
	TopLevel(namespace: Null<Array<String>>);
	ClassMember;
}

class VariableMember {
	public var name(default, null): String;
	public var type(default, null): Type;
	public var isStatic(default, null): Bool;
	public var expression(default, null): Null<TypedExpression>;
	public var varMemberType(default, null): VariableMemberType;

	var ref: Null<Ref<VariableMember>>;

	public function new(name: String, type: Type, isStatic: Bool, expression: Null<TypedExpression>, varMemberType: VariableMemberType) {
		this.name = name;
		this.type = type;
		this.isStatic = isStatic;
		this.expression = expression;
		this.varMemberType = varMemberType;
	}

	public function getRef(): Ref<VariableMember> {
		if(ref == null) {
			ref = new Ref<VariableMember>(this);
		}
		return ref;
	}

	public function getNamespaces(): Null<Array<String>> {
		return switch(varMemberType) {
			case TopLevel(namespaces): namespaces;
			default: null;
		}
	}
}
