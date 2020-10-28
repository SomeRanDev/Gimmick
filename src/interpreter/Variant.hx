package interpreter;

import ast.typing.Type;

import ast.scope.ScopeMember;

enum VariantType {
	TBool;
	TNum;
	TStr;
	TList(t: VariantType);
	TNullable(t: VariantType);
	TFunction(params: Array<VariantType>, returnType: VariantType);
}

enum Variant {
	Bool(b: Bool);
	Num(n: Float);
	Str(s: String);
	List(l: Array<Variant>, t: VariantType);
	Nullable(v: Null<Variant>, t: VariantType);
	Function(members: Array<ScopeMember>, paramNames: Array<String>, t: VariantType);
	NativeFunction(func: (self: Null<Variant>, params: Array<Variant>) -> Variant, t: VariantType);
}

class VariantHelper {
	public static function typeToVariantDefault(type: Type): Null<Variant> {
		var variantType = switch(type.type) {
			case Boolean: TBool;
			case Number(_): TNum;
			case String: TStr;
			default: null;
		}
		var result: Null<Variant> = null;
		if(variantType != null) {
			if(type.isOptional) {
				result = Nullable(null, variantType);
			} else {
				result = switch(variantType) {
					case TBool: Bool(false);
					case TNum: Num(0.0);
					case TStr: Str("");
					default: null;
				}
			}
		}
		return result;
	}

	public static function typeString(v: Variant): String {
		return typeToString(type(v));
	}

	public static function type(v: Variant): VariantType {
		return switch(v) {
			case Bool(_): TBool;
			case Num(_): TNum;
			case Str(_): TStr;
			case List(_, t): TList(t);
			case Nullable(_, t): TNullable(t);
			case Function(_, _, t): t;
			case NativeFunction(_, t): t;
		}
	}

	public static function typeToString(t: VariantType): String {
		return switch(t) {
			case TBool: "bool";
			case TNum: "number";
			case TStr: "string";
			case TList(t): "list<" + typeToString(t) + ">";
			case TNullable(t): typeToString(t) + "?";
			case TFunction(p, rt): "func(" + p.map(p -> typeToString(p)).join(", ") + ") -> " + typeToString(rt);
		}
	}

	public static function isBool(v: Variant): Bool {
		return switch(v) {
			case Bool(_): true;
			default: false;
		}
	}

	public static function isNumber(v: Variant): Bool {
		return switch(v) {
			case Num(_): true;
			default: false;
		}
	}

	public static function isString(v: Variant): Bool {
		return switch(v) {
			case Str(_): true;
			default: false;
		}
	}

	public static function isNullable(v: Variant): Bool {
		return switch(v) {
			case Nullable(_, _): true;
			default: false;
		}
	}

	public static function toBool(v: Variant, def: Bool = false): Bool {
		return switch(v) {
			case Bool(b): b;
			default: def;
		}
	}

	public static function toNumber(v: Variant, def: Float = 0): Float {
		return switch(v) {
			case Num(i): i;
			default: def;
		}
	}

	public static function toInt(v: Variant, def: Int = 0): Int {
		return switch(v) {
			case Num(i): Std.int(i);
			default: def;
		}
	}

	public static function toString(v: Variant, def: String = ""): String {
		return switch(v) {
			case Str(s): s;
			default: def;
		}
	}

	public static function toNullableVariant(v: Variant, def: Null<Variant> = null): Null<Variant> {
		return switch(v) {
			case Nullable(v, _): v;
			default: def;
		}
	}
}
