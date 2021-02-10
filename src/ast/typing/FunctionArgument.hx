package ast.typing;

import ast.scope.members.VariableMember;

import ast.typing.Type;

import parsers.Parser;
import parsers.expr.Position;
import parsers.expr.TypedExpression;

class FunctionArgument {
	public var name(default, null): String;
	public var type(default, null): Type;
	public var expr(default, null): Null<TypedExpression>;

	public function new(name: String, type: Type, expr: Null<TypedExpression>) {
		this.name = name;
		this.type = type;
		this.expr = expr;
	}

	public function toVarMember(): VariableMember {
		return new VariableMember(name, type, false, false, Position.BLANK, null, null, TopLevel(null));
	}

	public function resolveUnknownNamedType(parser: Parser): Bool {
		return type.resolveUnknownNamedType(parser);
	}
}
