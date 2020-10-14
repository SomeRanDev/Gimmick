package ast.typing;

import basic.Ref;

import ast.typing.Type;
import ast.typing.FunctionArgument;

import parsers.expr.TypedExpression;

class FunctionType {
	public var arguments(default, null): Array<FunctionArgument>;
	public var returnType(default, null): Type;

	var ref: Null<Ref<FunctionType>>;

	public function new(arguments: Array<FunctionArgument>, returnType: Type) {
		this.arguments = arguments;
		this.returnType = returnType;
	}

	public function getRef(): Ref<FunctionType> {
		if(ref == null) {
			ref = new Ref<FunctionType>(this);
		}
		return ref;
	}
}
