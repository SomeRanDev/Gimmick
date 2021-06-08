package ast.typing;

import basic.Ref;
using basic.Null;

import ast.typing.NumberType;
import ast.typing.FunctionType;

using ast.scope.ScopeMember;
import ast.scope.ScopeParameterSearchResult;
import ast.scope.members.NamespaceMember;

import ast.scope.Scope;

import parsers.Parser;

import parsers.error.ErrorTypeAndParams;

import parsers.error.Error;
import parsers.error.ErrorType;
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
	TypeSelf(cls: Type, isAlloc: Bool);
	External(name: Null<String>, typeParams: Null<Array<Type>>);
	Unknown;
	UnknownFunction;
	UnknownNamed(name: String, typeParams: Null<Array<Type>>);
	Template(name: String);
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

	static function compareTypeArrays(one: Null<Array<Type>>, two: Null<Array<Type>>) {
		if(one == null) return two == null;
		if(two == null) return false;
		if(one.length != two.length) return false;
		var result = true;
		for(i in 0...one.length) {
			if(!one[i].baseTypesEqual(two[i])) {
				result = false;
				break;
			}
		}
		return result;
	}

	public function baseTypesEqual(other: Type): Bool {
		if(isAlloc() || other.isAlloc()) return false;

		final refType = isRefType();
		if(refType != null) return refType.baseTypesEqual(other);

		final otherRefType = other.isRefType();
		if(otherRefType != null) return baseTypesEqual(otherRefType);

		/*
		{
			final templateName = isTemplate();
			final otherName = other.isTemplate();
			if(templateName != null && otherName != null) {
				return templateName == otherName;
			} else if(templateName != null) {
				final newType = scope.getTemplateOverride(templateName);
				if(newType != null) return newType.baseTypesEqual(other, scope);
			} else if(otherName != null) {
				final newType = scope.getTemplateOverride(otherName);
				if(newType != null) return baseTypesEqual(newType, scope);
			}
		}
		*/

		switch([type, other.type]) {
			case [TypeType.List(t), TypeType.List(otherT)]: { return t.baseTypesEqual(otherT); }
			case [TypeType.Pointer(t), TypeType.Pointer(otherT)]: { return t.baseTypesEqual(otherT); }
			case [TypeType.TypeSelf(t, _), TypeType.TypeSelf(otherT, _)]: {
				return t.baseTypesEqual(otherT);
			}
			case [TypeType.Tuple(types), TypeType.Tuple(otherTypes)]: {
				return compareTypeArrays(types, otherTypes);
			}
			case [TypeType.Function(func, params), TypeType.Function(otherFunc, otherParams)]: {
				return func.get().equals(otherFunc.get()) && compareTypeArrays(params, otherParams);
			}
			case [TypeType.Class(cls, params), TypeType.Class(otherCls, otherParams)]: {
				return cls.get().equals(otherCls.get()) && compareTypeArrays(params, otherParams);
			}
			case [TypeType.External(name, params), TypeType.External(otherName, otherParams)]: {
				return name == otherName && compareTypeArrays(params, otherParams);
			}
			default: {}
		}

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
		if(isAny() || other.isAny()) {
			return null;
		}
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
		if(isAny() || other.isAny()) {
			return null;
		}
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
			case TypeType.UnknownNamed(name, params): {
				final newType = parser.scope.findTypeFromName(name);
				if(newType != null) {
					final resolvedParams = if(params == null) {
						null;
					} else {
						params.map(p -> {
							p.resolveUnknownNamedType(parser);
							p;
						});
					}
					newType.setTypeParams(resolvedParams);
					type = newType.type;
					return true;
				} else if(position != null) {
					Error.addErrorFromPos(ErrorType.UnknownType, position);
				}
			}
			case TypeType.List(t) | TypeType.Pointer(t) | TypeType.Reference(t): {
				return t.resolveUnknownNamedType(parser);
			}
			case TypeType.TypeSelf(t, isAlloc): {
				if(!isAlloc) {
					return t.resolveUnknownNamedType(parser);
				}
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

	public static function TypeSelf(cls: Type, isAlloc: Bool = false, isConst: Bool = false, isOptional: Bool = false): Type {
		return new Type(TypeType.TypeSelf(cls, isAlloc), isConst, isOptional);
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

	public static function UnknownNamed(name: String, typeParams: Null<Array<Type>>, isConst: Bool = false, isOptional: Bool = false): Type {
		return new Type(TypeType.UnknownNamed(name, typeParams), isConst, isOptional);
	}

	public static function Template(name: String, isConst: Bool = false, isOptional: Bool = false): Type {
		return new Type(TypeType.Template(name), isConst, isOptional);
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
				final templateType = scope.getTemplateOverride(name);
				if(templateType != null) {
					Type.TypeSelf(templateType);
				} else {
					Type.UnknownNamed(name, null);
				}
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

	public function setTypeParams(typeParams: Null<Array<Type>>) {
		if(typeParams == null) return;
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
			case TypeType.UnknownNamed(name, _): {
				TypeType.UnknownNamed(name, typeParams);
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

	public function findAllAccessorMembersWithParameters(name: String, typeArgs: Null<Array<Type>>, params: Array<TypedExpression>): ScopeParameterSearchResult {
		switch(type) {
			case TypeType.Namespace(namespace): {
				final members = namespace.get().members.findWithParameters(name, typeArgs, params);
				if(members != null) {
					return members;
				}
			}
			case TypeType.Class(cls, typeParams): {
				final members = cls.get().members.findWithParameters(name, typeArgs, params);
				if(members != null) {
					return members;
				}
			}
			default: {}
		}
		return ScopeParameterSearchResult.fromEmpty();
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
				result += t.toString() + " list";
			}
			case TypeType.Function(func, typeParams): {
				result += func.get().toString();
				if(typeParams != null) {
					result = "(" + result + ")!" + typeParams;
				}
			}
			case TypeType.Class(cls, typeParams): {
				result += cls.get().name;
				if(typeParams != null) {
					final len = typeParams.length;
					final argStr = typeParams.map((p) -> p.toString()).join(", ");
					if(len == 1) result += "!";
					else if(len > 1) result += "!(";
					result += argStr;
					if(len > 1) result += ")";
				}
			}
			case TypeType.Namespace(namespace): {
				result += "namespace " + namespace.get().name;
			}
			case TypeType.Tuple(types): {
				final argStr = types.map((p) -> p.toString()).join(", ");
				result += "tuple!(" + argStr + ")";
			}
			case TypeType.Pointer(t): {
				result += t.toString() + " ptr";
			}
			case TypeType.Reference(t): {
				result += t.toString() + " ref";
			}
			case TypeType.External(name, typeParams): {
				if(typeParams != null) {
					final paramStr = typeParams.map(function(p) { return p.toString(); }).join(", ");
					result += "external!(" + name + "!(" + paramStr + "))";
				} else {
					result += "external!" + name;
				}
			}
			case TypeType.UnknownNamed(name, typeParams): {
				result += "unknown (";
				if(typeParams != null) {
					final paramStr = typeParams.map(function(p) { return p.toString(); }).join(", ");
					result += name + "!(" + paramStr + ")";
				} else {
					result += name;
				}
				result += ")";
			}
			case TypeType.Template(name): {
				result += name + " (template)";
			}
			case TypeType.TypeSelf(type, _): {
				result += "class " + type.toString();
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

	public function isAny(): Bool {
		return switch(type) {
			case TypeType.Any: true;
			default: false;
		}
	}

	public function isVoid(): Bool {
		return switch(type) {
			case TypeType.Void: true;
			default: false;
		}
	}

	public function isClassType(): Null<Ref<ClassType>> {
		return switch(type) {
			case TypeType.Class(cls, _): cls;
			default: null;
		}
	}

	public function isTypeSelf(): Null<Type> {
		return switch(type) {
			case TypeType.TypeSelf(t, _): t;
			default: null;
		}
	}

	public function isAlloc(): Bool {
		return switch(type) {
			case TypeType.TypeSelf(_, isAlloc): isAlloc;
			default: false;
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

	public function isTemplate(): Null<String> {
		return switch(type) {
			case TypeType.Template(name): name;
			default: null;
		}
	}

	public function toTypeArgs(): Array<Type> {
		return switch(type) {
			case TypeType.Tuple(types): types.map(t -> t.isTypeSelf().or(t));
			default: [isTypeSelf().or(this)];
		}
	}

	public function resolveTemplateType(scope: Scope): Type {
		final name = isTemplate();
		if(name != null) {
			final result = scope.getTemplateOverride(name);
			return result == null ? this : result;
		}
		return this;
	}

	public function isGenericNumber(): Bool {
		return isNumber() == NumberType.Any;
	}

	public function hasTemplate(): Bool {
		return templateArgMaximum() > 0;
	}

	public function templateArguments(): Null<Array<TemplateArgument>> {
		return switch(type) {
			case TypeType.Function(funcType, _): funcType.get().templateArguments;
			case TypeType.Class(clsType, _): clsType.get().templateArguments;
			case TypeType.External(_, _): [];
			default: null;
		}
	}

	public function typeArguments(): Null<Array<Type>> {
		return switch(type) {
			case TypeType.Function(_, args) | TypeType.Class(_, args) | TypeType.External(_, args): args;
			default: null;
		}
	}

	public function templateArgMaximum(): Int {
		return switch(type) {
			case TypeType.Function(_, _) | TypeType.Class(_, _): {
				final args = templateArguments();
				args != null ? args.length : 0;
			}
			case TypeType.External(_, _): {
				99999999;
			}
			default: {
				0;
			}
		}
	}

	public function applyTemplateArgs(args: Array<Type>): Null<Type> {
		if(matchesTemplateArgs(args)) {
			return switch(type) {
				case TypeType.Function(funcType, _): Type.Function(funcType, args, isConst, isOptional);
				case TypeType.Class(clsType, _): Type.Class(clsType, args, isConst, isOptional);
				case TypeType.External(name, _): Type.External(name, args, isConst, isOptional);
				default: null;
			}
		}
		return null;
	}

	public function matchesTemplateArgs(args: Array<Type>): Bool {
		if(args.length > templateArgMaximum()) {
			Error.addErrorPromiseDirect("matchTemplateArgs", ErrorType.TooManyTemplateParameters, [Std.string(templateArgMaximum()), Std.string(args.length)], 0);
			return false;
		}
		switch(type) {
			case TypeType.External(_, _): return true;
			default: {}
		}
		final typeArgs = templateArguments();
		if(typeArgs == null) {
			Error.addErrorPromiseDirect("matchTemplateArgs", ErrorType.TypeDoesNotHaveTemplate, [], 0);
			return false;
		}
		for(i in 0...args.length) {
			final invalidRestriction = args[i].validTemplateArgument(typeArgs[i].type);
			if(invalidRestriction != null) {
				Error.addErrorPromiseDirect("matchTemplateArgs", ErrorType.TypeDoesNotMeetRequirement, [args[i].toString(), invalidRestriction.toString()], i + 1);
				return false;
			}
		}
		for(i in args.length...typeArgs.length) {
			if(typeArgs[i].defaultType == null) {
				Error.addErrorPromiseDirect("matchTemplateArgs", ErrorType.NotEnoughTemplateParameters, [Std.string(typeArgs.length), Std.string(i - 1)], 0);
				return false;
			}
		}
		return true;
	}

	public function validTemplateArgument(templateType: TemplateType): Null<TemplateArgumentRequirement> {
		final restrictions = templateType.restrictions;
		if(restrictions != null) {
			for(r in restrictions) {
				switch(r.type) {
					case HasVariable(name, type): {
						if(!hasVariableType(name, type)) {
							return r;
						}
					}
					case HasFunction(name, funcType): {
						if(!hasFunctionType(name, funcType)) {
							return r;
						}
					}
					case HasAttribute(name): {
						switch(type) {
							case TypeType.Class(cls, _): {
								if(!cls.get().hasAttribute(name)) {
									return r;
								}
							}
							default: return r;
						}
					}
					case Extends(type): {
						if(!extendsFrom(type)) {
							return r;
						}
					}
					case Matches(template): {
						if(validTemplateArgument(template) != null) {
							return r;
						}
					}
				}
			}
		}
		return null;
	}

	public function revealTemplateArgsToScope(scope: Scope) {
		final templateArgs = templateArguments();
		final typeArgs = typeArguments();
		if(templateArgs != null && typeArgs != null) {
			for(i in 0...templateArgs.length) {
				final type = if(i >= 0 && i < typeArgs.length) {
					typeArgs[i];
				} else {
					templateArgs[i].defaultType;
				}
				if(type != null) {
					scope.setTemplateOverride(templateArgs[i].name, type);
				}
			}
		}
	}

	public function hasVariableType(name: String, varType: Type): Bool {
		switch(type) {
			case TypeType.Class(cls, _): {
				return cls.get().members.hasVariableType(name, varType);
			}
			default: {}
		}
		return false;
	}

	public function hasFunctionType(name: String, funcType: FunctionType): Bool {
		switch(type) {
			case TypeType.Class(cls, _): {
				return cls.get().members.hasFunctionType(name, funcType);
			}
			default: {}
		}
		return false;
	}

	public function extendsFrom(other: Type): Bool {
		switch(type) {
			case TypeType.Class(cls, _): {
				return cls.get().extendsFrom(other);
			}
			default: {}
		}
		return false;
	}

	public function templateRequired(): Bool {
		function getResult(args: Null<Array<TemplateArgument>>): Bool {
			if(args != null) {
				for(a in args) {
					if(a.defaultType == null) return true;
				}
			}
			return false;
		}
		switch(type) {
			case TypeType.TypeSelf(t, _): {
				switch(t.type) {
					case TypeType.Class(cls, params): {
						if(params == null) {
							if(getResult(cls.get().templateArguments)) {
								return true;
							}
						}
					}
					default: {}
				}
			}
			case TypeType.Function(funcType, params): {
				if(params == null) {
					if(getResult(funcType.get().templateArguments)) {
						return true;
					}
				}
			}
			default: {}
		}
		return false;
	}

	public function applyTypeArguments(args: Null<Array<Type>> = null, templateArguments: Null<TemplateArgumentCollection> = null): Type {
		if(hasTemplate()) {
			if(args == null) args = this.typeArguments();
			if(args != null) {
				return switch(type) {
					case TypeType.Function(funcType, typeArgs): {
						final newFuncType = funcType.get().applyTypeArguments(args, templateArguments).getRef();
						Type.Function(newFuncType, typeArgs, isConst, isOptional);
					}
					case TypeType.Class(clsType, typeArgs): {
						final newClsType = clsType.get().applyTypeArguments(args, templateArguments).getRef();
						Type.Class(newClsType, typeArgs, isConst, isOptional);
					}
					case TypeType.External(name, typeArgs): {
						Type.External(name, typeArgs, isConst, isOptional);
					}
					default: this;
				}
			}
		}
		return this;
	}

	public function convertToAlloc(): Null<Type> {
		return switch(type) {
			case TypeType.TypeSelf(type, isAlloc): TypeSelf(type, true);
			default: null;
		}
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
