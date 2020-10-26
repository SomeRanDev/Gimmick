package interpreter;

import ast.typing.Type;

enum Variant {
	Bool(b: Bool);
	Num(n: Float);
	Str(s: String);
}

class VariantHelper {
	public static function typeToVariantDefault(type: Type): Null<Variant> {
		return switch(type.type) {
			case Boolean: Bool(false);
			case Number(_): Num(0.0);
			case String: Str("");
			default: null;
		}
	}

	public static function typeString(v: Variant): String {
		return switch(v) {
			case Bool(_): "bool";
			case Num(_): "number";
			case Str(_): "string";
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
}
