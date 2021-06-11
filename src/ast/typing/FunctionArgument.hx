package ast.typing;

import ast.scope.members.VariableMember;

import ast.typing.Type;

import parsers.Parser;
import parsers.expr.Position;
import parsers.expr.TypedExpression;

class FunctionArgument {
	public var name(default, null): String;
	public var type(default, null): Type;
	public var position(default, null): Position;
	public var expr(default, null): Null<TypedExpression>;

	public function new(name: String, type: Type, position: Position, expr: Null<TypedExpression>) {
		this.name = name;
		this.type = type;
		this.position = position;
		this.expr = expr;
	}

	public function clone(): FunctionArgument {
		return new FunctionArgument(name, type, position, expr);
	}

	public function setType(type: Type) {
		this.type = type;
	}

	public function toVarMember(): VariableMember {
		return new VariableMember(name, type, false, false, position, null, null, TopLevel(null));
	}

	public function resolveUnknownNamedType(parser: Parser): Bool {
		return type.resolveUnknownNamedType(parser);
	}
}
