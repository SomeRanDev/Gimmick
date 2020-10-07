package ast.typing;

import basic.Ref;

import ast.typing.Type;

import parsers.expr.TypedExpression;

class FunctionType {
	public var arguments(default, null): Array<Type>;
	public var defaultArguments(default, null): Null<Array<Null<TypedExpression>>>;
	public var returnType(default, null): Type;

	var ref: Null<Ref<FunctionType>>;

	public function new(arguments: Array<Type>, defaultArguments: Null<Array<Null<TypedExpression>>>, returnType: Type) {
		this.arguments = arguments;
		this.defaultArguments = defaultArguments;
		this.returnType = returnType;
	}

	public function getRef(): Ref<FunctionType> {
		if(ref == null) {
			ref = new Ref<FunctionType>(this);
		}
		return ref;
	}
}
