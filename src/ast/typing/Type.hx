package ast.typing;

import basic.Ref;

import ast.typing.NumberType;
import ast.typing.FunctionType;

using ast.scope.ScopeMember;
import ast.scope.members.NamespaceMember;

import ast.scope.Scope;

import parsers.Parser;
import parsers.Error;
import parsers.ErrorType;
import parsers.expr.Position;
import parsers.expr.Literal;
import parsers.expr.Expression;
import parsers.expr.InfixOperator;
import parsers.expr.PrefixOperator;
import parsers.expr.SuffixOperator;
using parsers.expr.TypedExpression;

using haxe.EnumTools;

enum TypeType {
	Void;
	Any;
	Null;
	Boolean;
	Number(type: NumberType);
	String;
	List(type: Type);
	Pointer(type: Type);
	Reference(type: Type);
	Function(func: Ref<FunctionType>, typeParams: Null<Array<Type>>);
	Class(cls: Ref<ClassType>, typeParams: Null<Array<Type>>);
	Namespace(namespace: Ref<NamespaceMember>);
	Tuple(types: Array<Type>);
	TypeSelf(cls: Type);
	External(name: Null<String>, typeParams: Null<Array<Type>>);
	Unknown;
	UnknownFunction;
	UnknownNamed(name: String);
	Template(index: Int);
}

class Type {
	public var type(default, null): TypeType;
	public var isConst(default, null): Bool;
	public var isOptional(default, null): Bool;
	public var position(default, null): Null<Position>;

	public function new(type: TypeType, isConst: Bool, isOptional: Bool) {
		this.type = type;
		this.isConst = isConst;
		this.isOptional = isOptional;
		position = null;
	}

	public function setPosition(pos: Position) {
		position = pos;
	}

	public function clone(): Type {
		return new Type(type, isConst, isOptional);
	}

	public function baseTypesEqual(other: Type): Bool {
		final refType = isRefType();
		if(refType != null) refType.type.equals(other.type);

		final otherRefType = other.isRefType();
		if(otherRefType != null) type.equals(otherRefType.type);

		return type.equals(other.type);
	}

	public function equals(other: Type): Bool {
		return baseTypesEqual(other) && isConst == other.isConst && isOptional == other.isOptional;
	}

	public function setConst(v: Bool = true) {
		isConst = v;
	}

	public function setOptional() {
		isOptional = true;
	}

	public function isUnknown(): Bool {
		return switch(type) {
			case TypeType.Unknown: true;
			default: false;
		}
	}

	public function canBePassed(other: Type): Null<ErrorType> {
		if(other.isNull()) {
			return isOptional ? null : ErrorType.CannotAssignNullToNonOptional;
		}
		if(isGenericNumber() && other.isNumber() != null) {
			return null;
		}
		if(other.isNumber() == NumberType.Int && isNumber() != null) {
			return null;
		}
		if(!baseTypesEqual(other)) {
			return ErrorType.CannotAssignThisTypeToThatType;
		}
		if(!isOptional && other.isOptional) {
			return ErrorType.CannotAssignThisTypeToThatType;
		}
		return null;
	}

	public function canBeAssigned(other: Type): Null<ErrorType> {
		if(!baseTypesEqual(other)) {
			return ErrorType.CannotAssignThisTypeToThatType;
		}
		if(isConst) {
			return ErrorType.CannotAssignToConst;
		}
		if(!isOptional && other.isOptional) {
			return ErrorType.CannotAssignThisTypeToThatType;
		}
		return null;
	}

	public function resolveUnknownNamedType(parser: Parser): Bool {
		switch(type) {
			case TypeType.UnknownNamed(name): {
				final newType = parser.scope.findTypeFromName(name);
				if(newType != null) {
					type = newType.type;
					return true;
				} else if(position != null) {
					Error.addErrorFromPos(ErrorType.UnknownType, position);
				}
			}
			case TypeType.List(t) | TypeType.Pointer(t) | TypeType.Reference(t) | TypeType.TypeSelf(t): {
				return t.resolveUnknownNamedType(parser);
			}
			case TypeType.Function(_, typeParams) | TypeType.Class(_, typeParams) | TypeType.External(_, typeParams): {
				var result = false;
				if(typeParams != null) {
					for(t in typeParams) {
						if(t.resolveUnknownNamedType(parser)) {
							result = true;
						}
					}
				}
				return result;
			}
			case TypeType.Tuple(types): {
				var result = false;
				for(t in types) {
					if(t.resolveUnknownNamedType(parser)) {
						result = true;
					}
				}
				return result;
			}
			default: {}
		}
		return false;
	}

	public function bothSameAndNotNull(other: Type): Bool {
		return baseTypesEqual(other) && !isOptional && !other.isOptional;
	}

	public static function Void(isConst: Bool = false, isOptional: Bool = false): Type {
		return new Type(TypeType.Void, isConst, isOptional);
	}

	public static function Any(isConst: Bool = false, isOptional: Bool = false): Type {
		return new Type(TypeType.Any, isConst, isOptional);
	}

	public static function Null(): Type {
		return new Type(TypeType.Null, true, true);
	}

	public static function Boolean(isConst: Bool = false, isOptional: Bool = false): Type {
		return new Type(TypeType.Boolean, isConst, isOptional);
	}

	public static function Number(type: NumberType, isConst: Bool = false, isOptional: Bool = false): Type {
		return new Type(TypeType.Number(type), isConst, isOptional);
	}

	public static function String(isConst: Bool = false, isOptional: Bool = false): Type {
		return new Type(TypeType.String, isConst, isOptional);
	}

	public static function List(type: Type, isConst: Bool = false, isOptional: Bool = false): Type {
		return new Type(TypeType.List(type), isConst, isOptional);
	}

	public static function Pointer(type: Type, isConst: Bool = false, isOptional: Bool = false): Type {
		return new Type(TypeType.Pointer(type), isConst, isOptional);
	}

	public static function Reference(type: Type, isConst: Bool = false, isOptional: Bool = false): Type {
		return new Type(TypeType.Reference(type), isConst, isOptional);
	}

	public static function Function(func: Ref<FunctionType>, typeParams: Null<Array<Type>>, isConst: Bool = false, isOptional: Bool = false): Type {
		return new Type(TypeType.Function(func, typeParams), isConst, isOptional);
	}

	public static function Class(cls: Ref<ClassType>, typeParams: Null<Array<Type>>, isConst: Bool = false, isOptional: Bool = false): Type {
		return new Type(TypeType.Class(cls, typeParams), isConst, isOptional);
	}

	public static function Namespace(namespace: Ref<NamespaceMember>): Type {
		return new Type(TypeType.Namespace(namespace), false, false);
	}

	public static function Tuple(types: Array<Type>, isConst: Bool = false, isOptional: Bool = false): Type {
		return new Type(TypeType.Tuple(types), isConst, isOptional);
	}

	public static function TypeSelf(cls: Type, isConst: Bool = false, isOptional: Bool = false): Type {
		return new Type(TypeType.TypeSelf(cls), isConst, isOptional);
	}

	public static function External(name: Null<String>, typeParams: Null<Array<Type>>, isConst: Bool = false, isOptional: Bool = false): Type {
		return new Type(TypeType.External(name, typeParams), isConst, isOptional);
	}

	public static function Unknown(isConst: Bool = false, isOptional: Bool = false): Type {
		return new Type(TypeType.Unknown, isConst, isOptional);
	}

	public static function UnknownFunction(isConst: Bool = false, isOptional: Bool = false): Type {
		return new Type(TypeType.UnknownFunction, isConst, isOptional);
	}

	public static function UnknownNamed(name: String, isConst: Bool = false, isOptional: Bool = false): Type {
		return new Type(TypeType.UnknownNamed(name), isConst, isOptional);
	}

	public static function fromLiteral(literal: Literal, scope: Scope, thisType: Null<Type>): Null<Type> {
		return switch(literal) {
			case Literal.Null: Type.Null();
			case Literal.Boolean(_): Type.Boolean();
			case Literal.Number(_, _, type): Type.Number(type);
			case Literal.String(_, _, _): Type.String();
			case Literal.Tuple(exprs): {
				var types: Array<Type> = [];
				for(e in exprs) {
					final t = e.getType();
					if(t != null) {
						types.push(t);
					} else {
						types.push(Type.Unknown());
						break;
					}
				}
				types == null ? null : Type.Tuple(types);
			}
			case Literal.Name(name, namespaces): {
				Type.UnknownNamed(name);
			}
			case Literal.TypeName(type): {
				Type.TypeSelf(type);
			}
			case Literal.EnclosedExpression(expr): {
				return expr.getType();
			}
			case Literal.This: {
				return thisType;
			}
			default: null;
		}
	}

	public function setTypeParams(typeParams: Array<Type>) {
		final result: TypeType = switch(type) {
			case TypeType.Function(func, _): {
				TypeType.Function(func, typeParams);
			}
			case TypeType.Class(cls, _): {
				TypeType.Class(cls, typeParams);
			}
			case TypeType.List(type): {
				TypeType.List(typeParams.length > 0 ? typeParams[0] : type);
			}
			case TypeType.Pointer(type): {
				TypeType.Pointer(typeParams.length > 0 ? typeParams[0] : type);
			}
			case TypeType.Reference(type): {
				TypeType.Reference(typeParams.length > 0 ? typeParams[0] : type);
			}
			case TypeType.External(name, _): {
				TypeType.External(name, typeParams);
			}
			default: {
				null;
			}
		};
		if(result != null) {
			type = result;
		}
	}

	public function appendTypeParam(param: Type) {
		final result = switch(type) {
			case TypeType.Function(func, typeParams): {
				TypeType.Function(func, typeParams == null ? [param] : [param].concat(typeParams));
			}
			case TypeType.Class(cls, typeParams): {
				TypeType.Class(cls, typeParams == null ? [param] : [param].concat(typeParams));
			}
			case TypeType.List(type): {
				TypeType.List(param);
			}
			case TypeType.Pointer(type): {
				TypeType.Pointer(param);
			}
			case TypeType.Reference(type): {
				TypeType.Reference(param);
			}
			case TypeType.External(name, typeParams): {
				TypeType.External(name, typeParams == null ? [param] : [param].concat(typeParams));
			}
			default: {
				null;
			}
		};
		if(result != null) {
			type = result;
		}
	}

	public function findAccessorMember(name: String): Null<ScopeMember> {
		switch(type) {
			case TypeType.Namespace(namespace): {
				final member = namespace.get().members.find(name);
				if(member != null) {
					return member;
				}
			}
			case TypeType.Class(cls, typeParams): {
				final member = cls.get().members.find(name);
				if(member != null) {
					return member;
				}
			}
			default: {}
		}
		return null;
	}

	public function findAccessorMemberType(name: String): Null<Type> {
		final result = findAccessorMember(name);
		if(result != null) {
			return result.getType();
		}
		return null;
	}

	public function findAllAccessorMembersWithParameters(name: String, params: Array<TypedExpression>): Null<Array<ScopeMember>> {
		switch(type) {
			case TypeType.Namespace(namespace): {
				final members = namespace.get().members.findWithParameters(name, params);
				if(members != null) {
					return members;
				}
			}
			case TypeType.Class(cls, typeParams): {
				final members = cls.get().members.findWithParameters(name, params);
				if(members != null) {
					return members;
				}
			}
			default: {}
		}
		return null;
	}

	public function toString(): String {
		var result = "";
		if(isConst) {
			result += "const ";
		}
		switch(type) {
			case TypeType.Void | TypeType.Null: {
				result += "void";
			}
			case TypeType.Boolean: {
				result += "bool";
			}
			case TypeType.Unknown: {
				result += "unknown";
			}
			case TypeType.Number(num): {
				result += Std.string(num).toLowerCase();
			}
			case TypeType.String: {
				result += "string";
			}
			case TypeType.List(t): {
				result += "list<" + t.toString() + ">";
			}
			case TypeType.Function(func, typeParams): {
				result += func.get().toString();
			}
			case TypeType.Class(cls, typeParams): {
				result += cls.get().name;
			}
			case TypeType.Namespace(namespace): {
				result += "namespace " + namespace.get().name;
			}
			case TypeType.Tuple(types): {
				final argStr = types.map((p) -> p.toString()).join(", ");
				result += "tuple<" + argStr + ">";
			}
			case TypeType.Pointer(t): {
				result += "ptr<" + t.toString() + ">";
			}
			case TypeType.Reference(t): {
				result += "ref<" + t.toString() + ">";
			}
			case TypeType.External(name, typeParams): {
				if(typeParams != null) {
					final paramStr = typeParams.map(function(p) { return p.toString(); }).join(", ");
					result += "external<" + name + "<" + paramStr + ">>";
				} else {
					result += "external<" + name + ">";
				}
			}
			default: {
				result += Std.string(type);
			}
		}
		if(isOptional) {
			result += "?";
		}
		return result;
	}

	public function getTypeSize(): Int {
		return switch(type) {
			case TypeType.Void: 0;
			case TypeType.Boolean: 1;
			case TypeType.Unknown: 9999;
			case TypeType.Number(num): {
				switch(num) {
					case NumberType.Char | NumberType.Byte: 1;
					case NumberType.Short | NumberType.UShort: 2;
					case NumberType.Int | NumberType.UInt: 4;
					case NumberType.Long | NumberType.ULong: 8;
					case NumberType.Thicc | NumberType.UThicc: 12;

					case NumberType.Int8 | NumberType.UInt8: 1;
					case NumberType.Int16 | NumberType.UInt16: 2;
					case NumberType.Int32 | NumberType.UInt32: 4;
					case NumberType.Int64 | NumberType.UInt64: 8;

					case NumberType.Float: 4;
					case NumberType.Double: 8;
					case NumberType.Triple: 12;

					default: 4;
				}
			}
			case TypeType.String: 8;
			case TypeType.List(t): t.getTypeSize() + 4;
			case TypeType.Function(func, typeParams): 4;
			case TypeType.Class(cls, typeParams): 99;
			case TypeType.Namespace(namespace): 0;
			case TypeType.Tuple(types): {
				var result = 0;
				for(t in types) {
					result += t.getTypeSize();
				}
				result;
			}
			case TypeType.Pointer(t): 8;
			case TypeType.Reference(t): 8;
			case TypeType.External(name, typeParams): 999;
			default: 9999;
		}
	}

	public function isNull(): Bool {
		return switch(type) {
			case TypeType.Null: true;
			default: false;
		}
	}

	public function isClassType(): Null<Ref<ClassType>> {
		return switch(type) {
			case TypeType.Class(cls, _): cls;
			default: null;
		}
	}

	public function isRefType(): Null<Type> {
		return switch(type) {
			case TypeType.Reference(refType): refType;
			default: null;
		}
	}

	public function isNumber(): Null<NumberType> {
		return switch(type) {
			case TypeType.Number(numType): numType;
			default: null;
		}
	}

	public function isGenericNumber(): Bool {
		return isNumber() == NumberType.Any;
	}

	public function findOverloadedInfixOperator(op: InfixOperator, rtype: Type): Null<ScopeMember> {
		switch(type) {
			case TypeType.Class(cls, typeParams): {
				final members = cls.get().members;
				for(mem in members) {
					switch(mem.type) {
						case InfixOperator(infixOp, func): {
							if(infixOp == op) {
								final funcType = func.get().type.get();
								if(funcType.arguments.length == 1) {
									if(funcType.arguments[0].type.canBePassed(rtype) == null) {
										return mem;
									}
								}
							}
						}
						default: {}
					}
				}
			}
			default: {}
		}
		return null;
	}

	public function findOverloadedPrefixOperator(op: PrefixOperator): Null<ScopeMember> {
		switch(type) {
			case TypeType.Class(cls, typeParams): {
				final members = cls.get().members;
				for(mem in members) {
					switch(mem.type) {
						case PrefixOperator(prefixOp, func): {
							if(prefixOp == op) {
								final funcType = func.get().type.get();
								if(funcType.arguments.length == 0) {
									return mem;
								}
							}
						}
						default: {}
					}
				}
			}
			default: {}
		}
		return null;
	}

	public function findOverloadedSuffixOperator(op: SuffixOperator): Null<ScopeMember> {
		switch(type) {
			case TypeType.Class(cls, typeParams): {
				final members = cls.get().members;
				for(mem in members) {
					switch(mem.type) {
						case SuffixOperator(suffixOp, func): {
							if(suffixOp == op) {
								final funcType = func.get().type.get();
								if(funcType.arguments.length == 0) {
									return mem;
								}
							}
						}
						default: {}
					}
				}
			}
			default: {}
		}
		return null;
	}
}
