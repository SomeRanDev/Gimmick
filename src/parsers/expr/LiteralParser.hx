package parsers.expr;

import parsers.Parser;
import parsers.error.Error;
import parsers.error.ErrorType;
import parsers.expr.Literal;
using parsers.expr.Expression;
using parsers.expr.TypedExpression;

import ast.typing.NumberType;

class LiteralParser {
	var parser: Parser;

	var numberTypeParsed: Null<NumberType>;

	public static final rawStringOperator = "r";
	public static final stringOperator = "\"";
	public static final multilineStringOperatorStart = "\"\"\"";
	public static final multilineStringOperatorEnd = "\"\"\"";

	public static final listSeparatorOperator = ",";
	public static final arrayOperatorStart = "[";
	public static final arrayOperatorEnd = "]";
	public static final tupleOperatorStart = "(";
	public static final tupleOperatorEnd = ")";

	public function new(parser: Parser) {
		this.parser = parser;
		numberTypeParsed = null;
	}

	public function parseLiteral(): Null<Literal> {
		var result = null;
		var count = 0;
		while(result == null && count <= 9) {
			switch(count) {
				case 0: result = parseNextNull();
				case 1: result = parseNextThis();
				case 2: result = parseNextBoolean();
				case 3: result = parseArrayLiteral();
				case 4: result = parseTupleOrEnclosedLiteral();
				case 5: result = parseNextMultilineString();
				case 6: result = parseNextString();
				case 7: result = parseNextNumber();
				case 8: result = parseTypeName();
				case 9: result = parseNextVarNameLiteral();
			}
			count++;
		}
		return result;
	}

	public function parseNextNull(): Null<Literal> {
		final word = parser.parseMultipleWords(["null", "none", "Null", "None"]);
		if(word != null) {
			return Null;
		}
		return null;
	}

	public function parseNextThis(): Null<Literal> {
		final word = parser.parseMultipleWords(["this", "self"]);
		if(word != null) {
			return This;
		}
		return null;
	}

	public function parseNextBoolean(): Null<Literal> {
		final word = parser.parseMultipleWords(["true", "false", "True", "False"]);
		if(word != null) {
			return Boolean(word == "true" || word == "True");
		}
		return null;
	}

	public function parseNextNumber(): Null<Literal> {
		var result = null;
		var count = 0;
		while(result == null && count <= 2) {
			switch(count) {
				case 0: result = parseNextHexNumber();
				case 1: result = parseNextBinaryNumber();
				case 2: result = parseDecimalNumber();
			}
			count++;
		}

		var literal: Null<Literal> = null;
		if(result != null && numberTypeParsed != null) {
			final format = count == 1 ? Hex : (count == 2 ? Binary : Decimal);
			literal = Number(result, format, numberTypeParsed);
		}
		
		return literal;
	}

	@:nullSafety(Off)
	public function parseDecimalNumber(): Null<String> {
		numberTypeParsed = null;

		var numberFlags = 0;
		var invalidChars = false;
		var charStart: Null<Int> = null;
		var gotDot = false;

		var result = null;
		if(parser.isNumberChar(parser.currentCharCode())) {
			result = "";
			while(parser.getIndex() < parser.getContentLength()) {
				final char = parser.currentChar();
				if(parser.isDecimalNumberChar(parser.currentCharCode())) {
					result += char;
				} else if(parser.currentCharCode() == 46 /* period */) {
					final isDecimal = parser.isDecimalNumberChar(parser.charCodeAt(parser.getIndex() + 1));
					if(!gotDot && isDecimal) {
						result += ".";
						gotDot = true;
					} else {
						break;
					}
				} else if(validNumberSuffixCharacters().contains(char)) {
					if(charStart == null) {
						charStart = parser.getIndex();
					}
					var amount = 0;
					switch(char) {
						case "u": {
							if(gotDot || (numberFlags & 1) != 0) invalidChars = true;
							numberFlags |= 1;
						}
						case "f": {
							if((numberFlags & 2) != 0) invalidChars = true;
							numberFlags |= 2;
						}
						case "l": {
							if((numberFlags & 8) != 0) invalidChars = true;
							numberFlags |= (numberFlags & 4) != 0 ? 8 : 4;
						}
					}
				} else {
					break;
				}
				if(parser.incrementIndex(1)) {
					break;
				}
			}
		}

		if(result != null) {
			if(!invalidChars) {
				numberTypeParsed = switch(numberFlags) {
					case 0: gotDot ? Double : Int;
					case 1: UInt;
					case 2: Float;
					case 4: gotDot ? Triple : Long;
					case 5: ULong;
					case 12: Thicc;
					case 13: UThicc;
					default: null;
				}
			}
			if(invalidChars || numberTypeParsed == null) {
				Error.addError(ErrorType.InvalidNumericCharacters, parser, charStart);
				numberTypeParsed = gotDot ? Double : Int;
			}
		}

		return result;
	}

	@:nullSafety(Off)
	public function parseHexOrBinaryNumber(isHex: Bool): Null<String> {
		final numberStarter = isHex ? "0x" : "0b";
		var result = null;
		if(parser.parseNextContent(numberStarter)) {
			result = numberStarter;
			while(parser.getIndex() < parser.getContentLength()) {
				final charCode = parser.currentCharCode();
				if(parser.isDecimalNumberChar(charCode)) {
					result += parser.currentChar();
				} else {
					break;
				}
				if(parser.incrementIndex(1)) {
					break;
				}
			}
		}
		return result;
	}

	public function validNumberSuffixCharacters(): Array<String> {
		return ["u", "l", "f"];
	}

	public function parseNextHexNumber(): Null<String> {
		return parseHexOrBinaryNumber(true);
	}

	public function parseNextBinaryNumber(): Null<String> {
		return parseHexOrBinaryNumber(false);
	}

	public function parseTypeName(): Null<Literal> {
		final namedType = parser.parseType(false);
		if(namedType != null) {
			return TypeName(namedType);
		}
		return null;
	}

	public function parseNextVarNameLiteral(): Null<Literal> {
		final result = parser.parseNextVarName();
		return result == null ? null : Name(result, null);
	}

	public function parseNextMultilineString(): Null<Literal> {
		var result: Null<String> = null;
		var start = multilineStringOperatorStart;
		var isRaw = false;
		var wasSlash = false;
		final end = multilineStringOperatorEnd;
		final endChar = end.charAt(0);
		if(parser.checkAhead(rawStringOperator)) {
			start = rawStringOperator + start;
			isRaw = true;
		}
		if(parser.parseNextContent(start)) {
			result = "";
			while(true) {
				final char = parser.currentChar();
				if(char == endChar) {
					if(parser.parseNextContent(end)) {
						break;
					}
				} else if(!wasSlash && char == "\\") {
					wasSlash = true;
				} else if(wasSlash) {
					if(char != null && !validEscapeCharacters().contains(char)) {
						Error.addError(UnknownEscapeCharacter, parser, parser.getIndex() - 1, 1);
					}
					wasSlash = false;
				}
				@:nullSafety(Off) result += char;
				if(char == "\n") {
					parser.incrementLine();
				}
				if(parser.incrementIndex(1)) {
					break;
				}
			}
		}
		return result == null ? null : String(result, true, isRaw);
	}

	public function parseNextString(): Null<Literal> {
		if(stringOperator.length == 0) return null;
		var result: Null<String> = null;
		final op = stringOperator;
		final opChar = op.charAt(0);
		var start = op;
		var isRaw = false;
		var wasSlash = false;
		if(parser.checkAhead(rawStringOperator)) {
			start = rawStringOperator + start;
			isRaw = true;
		}
		if(parser.parseNextContent(start)) {
			result = "";
			while(true) {
				final char = parser.currentChar();
				if(!wasSlash && char == opChar) {
					if(parser.parseNextContent(op)) {
						break;
					}
				} else if(!wasSlash && char == "\\") {
					wasSlash = true;
				} else if(char == "\n") {
					Error.addError(UnexpectedEndOfString, parser, parser.getIndex());
					break;
				} else if(wasSlash) {
					if(char != null && !validEscapeCharacters().contains(char)) {
						Error.addError(UnknownEscapeCharacter, parser, parser.getIndex() - 1, 1);
					}
					wasSlash = false;
					@:nullSafety(Off) result += char;
				} else {
					@:nullSafety(Off) result += char;
				}
				if(parser.incrementIndex(1)) {
					break;
				}
			}
		}
		return result == null ? null : String(result, false, isRaw);
	}

	public function validEscapeCharacters(): Array<String> {
		return ["n", "r", "t", "v", "f", "\\", "\"", "\'"];
	}

	public function parseArrayLiteral(): Null<Literal> {
		final exprs = parseListType(arrayOperatorStart, arrayOperatorEnd);
		return exprs == null ? null : List(exprs);
	}

	public function parseTupleOrEnclosedLiteral(): Null<Literal> {
		final exprs = parseListType(tupleOperatorStart, tupleOperatorEnd);
		if(exprs != null && exprs.length == 1) {
			return EnclosedExpression(exprs[0]);
		}
		return exprs == null ? null : Tuple(exprs);
	}

	public function parseListType(start: String, end: String): Null<Array<TypedExpression>> {
		var result: Null<Array<TypedExpression>> = null;
		if(parser.parseNextContent(start)) {
			result = [];
			while(true) {
				if(parser.parseNextContent(end)) {
					break;
				}
				parser.parseWhitespaceOrComments();
				final expr = parser.parseExpression(false);
				if(expr != null) {
					final typedExpr = expr.getType(parser, parser.isPreliminary() ? Preliminary : Normal);
					if(typedExpr != null) {
						result.push(typedExpr);
						parser.parseNextContent(listSeparatorOperator);
					}
				} else {
					break;
				}
			}
		}
		return result;
	}
}
