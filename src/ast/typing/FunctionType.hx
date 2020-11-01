package ast.typing;

import basic.Ref;

import ast.typing.Type;
import ast.typing.FunctionArgument;

import parsers.expr.TypedExpression;

enum FunctionThisType {
	None;
	StaticExtension;
	Class;
}

class FunctionType {
	public var arguments(default, null): Array<FunctionArgument>;
	public var returnType(default, null): Type;
	public var thisType(default, null): FunctionThisType;

	var ref: Null<Ref<FunctionType>>;

	public function new(arguments: Array<FunctionArgument>, returnType: Type) {
		this.arguments = arguments;
		this.returnType = returnType;
		thisType = None;
	}

	public function getRef(): Ref<FunctionType> {
		if(ref == null) {
			ref = new Ref<FunctionType>(this);
		}
		return ref;
	}

	public function prependArgument(name: String, type: Type) {
		arguments.insert(0, new FunctionArgument(name, type, null));
	}

	public function setStaticExtension() {
		thisType = StaticExtension;
	}
}
