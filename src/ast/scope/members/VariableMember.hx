package ast.scope.members;

import basic.Ref;

import parsers.expr.TypedExpression;

import ast.typing.Type;

class VariableMember {
	public var name(default, null): String;
	public var type(default, null): Type;
	public var isStatic(default, null): Bool;
	public var expression(default, null): Null<TypedExpression>;

	var ref: Null<Ref<VariableMember>>;

	public function new(name: String, type: Type, isStatic: Bool, expression: Null<TypedExpression>) {
		this.name = name;
		this.type = type;
		this.isStatic = isStatic;
		this.expression = expression;
	}

	public function getRef(): Ref<VariableMember> {
		if(ref == null) {
			ref = new Ref<VariableMember>(this);
		}
		return ref;
	}
}
