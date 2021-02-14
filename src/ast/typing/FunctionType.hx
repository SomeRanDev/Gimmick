package ast.typing;

import basic.Ref;

import ast.typing.Type;
import ast.typing.FunctionArgument;
import ast.typing.TemplateArgument;

import ast.scope.members.FunctionMember;

import parsers.Parser;
import parsers.error.Error;
import parsers.error.ErrorType;
import parsers.error.ErrorPromise;
import parsers.expr.TypedExpression;
import parsers.expr.Position;
import parsers.expr.Operator;

enum FunctionThisType {
	None;
	StaticExtension;
	Class;
	Constructor;
	Destructor;
	Operator(op: Operator);
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
			Error.addErrorFromPos(error, positions[index + 2], [typeA != null ? typeA.toString() : "", typeB != null ? typeB.toString() : ""]);
		}
	}
}

class FunctionType {
	public var member(default, null): Null<FunctionMember>;
	public var arguments(default, null): Array<FunctionArgument>;
	public var prependArguments(default, null): Array<FunctionArgument>;
	public var returnType(default, null): Type;
	public var thisType(default, null): FunctionThisType;
	public var templateArguments(default, null): Null<Array<TemplateArgument>>;

	public var classType(default, null): Null<Ref<ClassType>>;

	var ref: Null<Ref<FunctionType>>;

	public function new(arguments: Array<FunctionArgument>, returnType: Type) {
		this.arguments = arguments;
		this.returnType = returnType;
		thisType = None;
		prependArguments = [];
	}

	public function setMember(member: FunctionMember) {
		this.member = member;
	}

	public function getRef(): Ref<FunctionType> {
		if(ref == null) {
			ref = new Ref<FunctionType>(this);
		}
		return ref;
	}

	public function toString(funcString: String = "func") {
		final argStr = arguments.map((p) -> p.type.toString()).join(", ");
		return funcString + "(" + argStr + ") -> " + returnType.toString();
	}

	public function prependArgument(name: String, type: Type) {
		prependArguments.insert(0, new FunctionArgument(name, type, null));
	}

	public function allArguments(): Array<FunctionArgument> {
		return prependArguments.concat(arguments);
	}

	public function setStaticExtension() {
		thisType = StaticExtension;
	}

	public function setClassFunction() {
		thisType = Class;
	}

	public function setConstructor() {
		thisType = Constructor;
	}

	public function setDestructor() {
		thisType = Destructor;
	}

	public function setOperator(op: Operator) {
		thisType = Operator(op);
	}

	public function isConstructor() {
		return thisType == Constructor;
	}

	public function isDestructor() {
		return thisType == Destructor;
	}

	public function isOperator(): Null<Operator> {
		return switch(thisType) {
			case Operator(op): op;
			default: null;
		}
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
					return new FunctionTypePassResult(ErrorType.MissingFunctionParameter, -1, null, null);
				}
			}
		}
		return null;
	}

	public function setTemplateArguments(args: Null<Array<TemplateArgument>>) {
		if(args != null) {
			templateArguments = args;
		}
	}

	public function resolveUnknownTypes(parser: Parser): Bool {
		var result = false;
		for(a in arguments) {
			if(a.resolveUnknownNamedType(parser)) {
				result = true;
			}
		}
		return returnType.resolveUnknownNamedType(parser) || result;
	}

	public function setClassType(clsType: ClassType) {
		classType = clsType.getRef();
	}

	public function hasAttribute(attributeName: String): Bool {
		if(member != null && member.scopeMember != null) {
			return member.scopeMember.hasAttribute(attributeName);
		}
		return false;
	}
}
