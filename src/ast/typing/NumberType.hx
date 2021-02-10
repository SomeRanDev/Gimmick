package ast.typing;

enum NumberType {
	Any;

	Char;
	Short;
	Int;
	Long;
	Thicc;

	Byte;
	UShort;
	UInt;
	ULong;
	UThicc;

	Int8;
	Int16;
	Int32;
	Int64;

	UInt8;
	UInt16;
	UInt32;
	UInt64;

	Float;
	Double;
	Triple;
}

class NumberTypeHelper {
	public static function isWholeNumberType(type: NumberType) {
		return switch(type) {
			case Any | Float | Double | Triple: false;
			default: true;
		}
	}

	public static function priority(type: NumberType): Int {
		return switch(type) {
			case Any: 0;
			case Char | Int8: 1;
			case Short | Int16: 2;
			case Int | Int32: 3;
			case Long | Int64: 4;
			case Thicc: 5;
			case Byte | UInt8: 6;
			case UShort | UInt16: 7;
			case UInt | UInt32: 8;
			case ULong | UInt64: 9;
			case UThicc: 10;
			case Float: 11;
			case Double: 12;
			case Triple: 13;
		}
	}
}
