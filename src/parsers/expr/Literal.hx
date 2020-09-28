package parsers.expr;

import parsers.expr.Expression;

enum Literal {
	Name(name: String);
	Number(number: String, format: NumberLiteralFormat);
	String(content: String, isMultiline: Bool, isRaw: Bool);
	List(expressions: Array<Expression>);
	Tuple(expressions: Array<Expression>);
}

enum NumberLiteralFormat {
	Decimal;
	Hex;
	Binary;
}
