package ast.typing;

import basic.Ref;

import ast.typing.Type;
import ast.typing.FunctionArgument;

import parsers.Error;
import parsers.ErrorType;
import parsers.ErrorPromise;
import parsers.expr.TypedExpression;
import parsers.expr.Position;

enum FunctionThisType {
	None;
	StaticExtension;
	Class;
}

class FunctionTypePassResult extends ErrorPromise {
	public var error(default, null): ErrorType;
	public var typeA(default, null): Null<Type>;
	public var typeB(default, null): Null<Type>;
	public var index(default, null): Int;

	public function new(error: ErrorType, index: Int, typeA: Type = null, typeB: Type = null) {
		super();
		this.error = error;
		this.typeA = typeA;
		this.typeB = typeB;
		this.index = index;
	}

	public override function completeMulti(positions: Array<Position>) {
		if(index < positions.length) {
			Error.addErrorFromPos(error, positions[index], [typeA != null ? typeA.toString() : "", typeB != null ? typeB.toString() : ""]);
		}
	}
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

	public function canPassTypes(types: Array<Type>): Null<FunctionTypePassResult> {
		if(types.length > arguments.length) return new FunctionTypePassResult(ErrorType.TooManyFunctionParametersProvided, arguments.length, null, null);
		for(i in 0...types.length) {
			final t = types[i];
			final arg = arguments[i];
			final argType = arg.type;
			var err = argType.canBePassed(t);
			if(err != null) {
				if(err == ErrorType.CannotAssignThisTypeToThatType) {
					err = ErrorType.CannotPassThisForThat;
				}
				return new FunctionTypePassResult(err, i, t, argType);
			}
		}
		if(types.length < arguments.length) {
			for(i in types.length...arguments.length) {
				final arg = arguments[i];
				final optional = arg.expr != null;
				if(!optional) {
					return new FunctionTypePassResult(ErrorType.MissingFunctionParameter, i, null, null);
				}
			}
		}
		return null;
	}
}
