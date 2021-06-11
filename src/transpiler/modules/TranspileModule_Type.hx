package transpiler.modules;

import ast.typing.Type;
import ast.typing.Type.TypeType;
import ast.typing.NumberType;

class TranspileModule_Type {
	public static function transpile(type: Type): String {
		var result = "";
		if(type.isConst) {
			result += "const ";
		}
		result += transpileInternal(type.type);
		return result;
	}

	public static function transpileInternal(typeType: TypeType): String {
		switch(typeType) {
			case Void: {
				return "void";
			}
			case Any: {
				return "auto";
			}
			case Boolean: {
				return "bool";
			}
			case Number(numType): {
				switch(numType) {
					case Any: return "int";

					case Char: return "char";
					case Short: return "short";
					case Int: return "int";
					case Long: return "long";
					case Thicc: return "long long";

					case Byte: return "unsigned char";
					case UShort: return "unsigned short";
					case UInt: return "unsigned int";
					case ULong: return "unsigned long";
					case UThicc: return "unsigned long long";

					case Int8: return "int8_t";
					case Int16: return "int16_t";
					case Int32: return "int32_t";
					case Int64: return "int64_t";

					case UInt8: return "uint8_t";
					case UInt16: return "uint16_t";
					case UInt32: return "uint32_t";
					case UInt64: return "uint64_t";

					case Float: return "float";
					case Double: return "double";
					case Triple: return "long double";
				}
			}
			case String: {
				return "std::string";
			}
			case List(type): {
				return "std::vector<" + transpile(type) + ">";
			}
			case Pointer(type): {
				return transpile(type) + "*";
			}
			case Reference(type): {
				return transpile(type) + "&";
			}
			case Function(func, typeParams): {
				final argStr = [];
				for(a in func.get().arguments) {
					argStr.push(transpile(a.type));
				}
				return "std::function<" + transpile(func.get().returnType) + "(" + argStr.join(", ") + ")>";
			}
			case Class(cls, typeParams): {
				final argStr = [];
				if(typeParams != null) {
					for(a in typeParams) {
						argStr.push(transpile(a));
					}
				}
				final name = cls.get().name;
				if(argStr.length == 0) {
					return name;
				} else {
					return name + "<" + argStr.join(", ") + ">";
				}
			}
			case Tuple(types): {
				final argStr = [];
				for(a in types) {
					argStr.push(transpile(a));
				}
				return "std::tuple<" + argStr.join(", ") + ">";
			}
			case TypeSelf(type, isAlloc): {
				return transpile(type);
			}
			case External(name, typeParams): {
				final argStr = [];
				if(typeParams != null) {
					for(a in typeParams) {
						argStr.push(transpile(a));
					}
				}
				if(name != null) {
					if(argStr.length == 0) {
						return name;
					} else {
						return name + "<" + argStr.join(", ") + ">";
					}
				}
			}
			case Template(name): {
				return name;
			}
			default: {}
		}
		return "auto";
	}

	public static function transpilable(type: Type): Bool {
		return transpileInternal(type.type) != "auto";
	}

	public static function getDefaultAssignment(type: Type): Null<String> {
		switch(type.type) {
			case Boolean: {
				return "false";
			}
			case Number(numType): {
				switch(numType) {
					case Any: return "0";

					case Char: return "0";
					case Short: return "0";
					case Int: return "0";
					case Long: return "0l";
					case Thicc: return "0ll";

					case Byte: return "0u";
					case UShort: return "0u";
					case UInt: return "0u";
					case ULong: return "0ul";
					case UThicc: return "0ull";

					case Int8 | Int16 | Int32 | Int64: return "0";
					case UInt8 | UInt16 | UInt32 | UInt64: return "0";

					case Float: return "0.0f";
					case Double: return "0.0";
					case Triple: return "0.0";
				}
			}
			case String: {
				return "\"\"";
			}
			case Pointer(type): {
				return "nullptr";
			}
			case Function(func, typeParams): {
				return "nullptr";
			}
			default: {}
		}
		return null;
	}
}
