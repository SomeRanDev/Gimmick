package ast.scope.members;

import basic.Ref;

import ast.typing.FunctionType;

import ast.scope.ExpressionMember;

class FunctionMember {
	public var name(default, null): String;
	public var type(default, null): Ref<FunctionType>;

	public var exprMembers(default, null): Array<ExpressionMember>;

	var ref: Null<Ref<FunctionMember>>;

	public function new(name: String, type: Ref<FunctionType>) {
		this.name = name;
		this.type = type;
		exprMembers = [];
	}

	public function addMember(member: ExpressionMember) {
		exprMembers.push(member);
	}

	public function getRef(): Ref<FunctionMember> {
		if(ref == null) {
			ref = new Ref<FunctionMember>(this);
		}
		return ref;
	}
}
