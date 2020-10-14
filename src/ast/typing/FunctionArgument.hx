package ast.typing;

import ast.typing.Type;

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
}
