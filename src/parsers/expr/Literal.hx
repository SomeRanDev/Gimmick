package parsers.expr;

import parsers.expr.TypedExpression;

import ast.typing.Type;
import ast.typing.NumberType;

enum Literal {
	Name(name: String, namespaces: Null<Array<String>>);
	Null;
	Boolean(value: Bool);
	Number(number: String, format: NumberLiteralFormat, type: NumberType);
	String(content: String, isMultiline: Bool, isRaw: Bool);
	List(expressions: Array<TypedExpression>);
	Tuple(expressions: Array<TypedExpression>);
	TypeName(type: Type);
}

enum NumberLiteralFormat {
	Decimal;
	Hex;
	Binary;
}
