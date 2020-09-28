package parsers;

using StringTools;

import io.SourceFileManager;

import ast.SourceFile;

import parsers.Error;
import parsers.ErrorType;

import parsers.expr.Literal;
import parsers.expr.Expression;
import parsers.expr.ExpressionParser;

import parsers.modules.ParserModule;
import parsers.modules.ParserModule_Import;
import parsers.modules.ParserModule_Expression;

class Parser {
	public var content(default, null): String;
	public var manager(default, null): SourceFileManager;
	public var index(default, null): Int;
	public var lineNumber(default, null): Int;
	public var ended(default, null): Bool;

	public var hitCharFlag(default, null): Bool;
	public var literalParsed(default, null): Null<Literal>;

	var modules: Array<ParserModule>;
	var file: SourceFile;
	var currLineIndex: Int;

	public static final singleCommentOperator = "#";
	public static final multilineCommentOperatorStart = "###";
	public static final multilineCommentOperatorEnd = "###";

	public static final rawStringOperator = "r";
	public static final stringOperator = "\"";
	public static final multilineStringOperatorStart = "\"\"\"";
	public static final multilineStringOperatorEnd = "\"\"\"";

	public static final listSeparatorOperator = ",";
	public static final arrayOperatorStart = "[";
	public static final arrayOperatorEnd = "]";
	public static final tupleOperatorStart = "(";
	public static final tupleOperatorEnd = ")";

	public function new(content: String, manager: SourceFileManager, file: SourceFile) {
		this.content = content;
		this.manager = manager;
		index = 0;
		lineNumber = 1;
		ended = false;
		hitCharFlag = false;
		modules = [];
		this.file = file;
		currLineIndex = 0;
	}

	public function beginParse() {
		while(true) {
			final oldIndex = index;
			parse();
			if(oldIndex == index || indexOutsideParser()) {
				break;
			}
		}
	}

	function parse() {
		parseWhitespace();
		for(mod in modules) {
			if(mod.parse(this)) {
				break;
			}
		}
	}

	function indexOutsideParser(): Bool {
		return index >= content.length;
	}

	public function getIndex(): Int {
		return index;
	}

	public function getIndexFromLine(): Int {
		return index - currLineIndex;
	}

	public function getLineNumber(): Int {
		return lineNumber;
	}

	public function getRelativePath(): String {
		return file.pathInfo.relativePath;
	}

	// ======================================================
	// * Modes
	// ======================================================

	public function setMode_SourceFile() {
		modules = [
			ParserModule_Import.it,
			ParserModule_Expression.it
		];
	}

	// ======================================================
	// * Tools
	// ======================================================

	public function currentChar(): Null<String> {
		return charAt(index);
	}

	public function currentCharCode(): Null<Int> {
		return charCodeAt(index);
	}

	public function charAt(index: Int): Null<String> {
		return content.charAt(index);
	}

	public function charCodeAt(index: Int): Null<Int> {
		return content.charCodeAt(index);
	}

	public function charCodeIsNewLine(code: Int): Bool {
		return code == 10;
	}

	public function checkAhead(check: String): Bool {
		final end = index + check.length;
		if(end >= content.length) return false;
		for(i in index...end) {
			if(content.charAt(i) != check.charAt(i - index)) {
				return false;
			}
		}
		return true;
	}

	public function checkAheadWord(check: String): Bool {
		return checkAhead(check) && (!checkCharIsWordable(index + check.length) || (index + check.length >= content.length));
	}

	public function safelyCheckChar(pos: Int): Null<Int> {
		if(pos >= 0 && pos < content.length) {
			return content.fastCodeAt(pos);
		}
		return null;
	}

	public function checkCharIsWordable(pos: Int): Bool {
		final c = safelyCheckChar(pos);
		return c != null && isNameChar(c);
	}

	public function isNameCharStarter(c: Int): Bool {
		return (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c == 95;
	}

	public function isNumberChar(c: Int): Bool {
		return (c >= 48 && c <= 57);
	}

	public function isDecimalNumberChar(c: Int): Bool {
		return isNumberChar(c) || c == 95;
	}

	public function isHexNumberChar(c: Int): Bool {
		return isNumberChar(c) || (c >= 65 && c <= 70) || (c >= 97 && c <= 102) || c == 95;
	}

	public function isBinaryNumberChar(c: Int): Bool {
		return c == 48 || c == 49 || c == 95;
	}

	public function isNameChar(c: Int): Bool {
		return isNumberChar(c) || isNameCharStarter(c);
	}

	public function parseNextLiteral(): Null<Literal> {
		var result = null;
		var count = 0;
		while(result == null && count <= 5) {
			switch(count) {
				case 0: result = parseArrayLiteral();
				case 1: result = parseTupleLiteral();
				case 2: result = parseNextMultilineString();
				case 3: result = parseNextString();
				case 4: result = parseNextNumber();
				case 5: result = parseNextVarName();
			}
			count++;
		}
		return result;
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
		return result == null ? null : Number(result, count == 0 ? Hex : (count == 1 ? Binary : Decimal));
	}

	public function parseDecimalNumber(): Null<String> {
		var result = null;
		if(isNumberChar(currentCharCode())) {
			result = "";
			var gotDot = false;
			while(index < content.length) {
				if(isDecimalNumberChar(currentCharCode())) {
					result += currentChar();
				} else if(currentCharCode() == 46 /* period */) {
					if(!gotDot && isDecimalNumberChar(charCodeAt(index + 1))) {
						result += ".";
						gotDot = true;
					} else {
						break;
					}
				} else {
					break;
				}
				if(incrementIndex(1)) {
					break;
				}
			}
		}
		return result;
	}

	public function parseHexOrBinaryNumber(isHex: Bool): Null<String> {
		final numberStarter = isHex ? "0x" : "0b";
		var result = null;
		if(checkAhead(numberStarter)) {
			result = numberStarter;
			incrementIndex(numberStarter.length);
			while(index < content.length) {
				final charCode = currentCharCode();
				if(isDecimalNumberChar(charCode)) {
					result += currentChar();
				} else {
					break;
				}
				if(incrementIndex(1)) {
					break;
				}
			}
		}
		return result;
	}

	public function parseNextHexNumber(): Null<String> {
		return parseHexOrBinaryNumber(true);
	}

	public function parseNextBinaryNumber(): Null<String> {
		return parseHexOrBinaryNumber(false);
	}

	public function parseNextVarName(): Null<Literal> {
		var result = null;
		if(isNameCharStarter(currentCharCode())) {
			result = "";
			while(isNameChar(currentCharCode())) {
				result += currentChar();
				if(incrementIndex(1)) {
					break;
				}
			}
		}
		return result == null ? null : Name(result);
	}

	public function parseNextMultilineString(): Null<Literal> {
		var result = null;
		var start = multilineStringOperatorStart;
		var isRaw = false;
		var wasSlash = false;
		final end = multilineStringOperatorEnd;
		final endChar = end.charAt(0);
		if(checkAhead(rawStringOperator)) {
			start = rawStringOperator + start;
			isRaw = true;
		}
		if(checkAhead(start)) {
			incrementIndex(start.length);
			result = "";
			while(true) {
				final char = currentChar();
				if(char == endChar) {
					if(checkAhead(end)) {
						incrementIndex(end.length);
						break;
					}
				} else if(!wasSlash && char == "\\") {
					wasSlash = true;
				} else if(wasSlash) {
					if(!validEscapeCharacters().contains(char)) {
						Error.addError(UnknownEscapeCharacter, this, getIndexFromLine() - 1, 1);
					}
					wasSlash = false;
				}
				result += char;
				if(char == "\n") {
					incrementLine();
				}
				if(incrementIndex(1)) {
					break;
				}
			}
		}
		return result == null ? null : String(result, true, isRaw);
	}

	public function parseNextString(): Null<Literal> {
		if(stringOperator.length == 0) return null;
		var result = null;
		final op = stringOperator;
		final opChar = op.charAt(0);
		var start = op;
		var isRaw = false;
		var wasSlash = false;
		if(checkAhead(rawStringOperator)) {
			start = rawStringOperator + start;
			isRaw = true;
		}
		if(checkAhead(start)) {
			incrementIndex(start.length);
			result = "";
			while(true) {
				final char = currentChar();
				if(char == opChar) {
					if(checkAhead(op)) {
						incrementIndex(op.length);
						break;
					}
				} else if(!wasSlash && char == "\\") {
					wasSlash = true;
				} else if(char == "\n") {
					Error.addError(UnexpectedEndOfString, this, getIndexFromLine());
					break;
				} else if(wasSlash) {
					if(!validEscapeCharacters().contains(char)) {
						Error.addError(UnknownEscapeCharacter, this, getIndexFromLine() - 1, 1);
					}
					wasSlash = false;
				}
				result += char;
				if(incrementIndex(1)) {
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

	public function parseTupleLiteral(): Null<Literal> {
		final exprs = parseListType(tupleOperatorStart, tupleOperatorEnd);
		return exprs == null ? null : Tuple(exprs);
	}

	public function parseListType(start: String, end: String): Null<Array<Expression>> {
		var result = null;
		if(checkAhead(start)) {
			result = [];
			incrementIndex(start.length);
			while(true) {
				if(checkAhead(end)) {
					incrementIndex(end.length);
					break;
				}
				parseWhitespaceOrComments();
				final expr = parseExpression();
				if(expr != null) {
					result.push(expr);
					if(checkAhead(listSeparatorOperator)) {
						incrementIndex(listSeparatorOperator.length);
					}
				} else {
					break;
				}
			}
		}
		return result;
	}

	public function parseExpression(): Null<Expression> {
		final start = getIndex();
		final exprParser = new ExpressionParser(this);
		if(exprParser.successful()) {
			return exprParser.buildExpression();
		}
		return null;
	}

	public function parseWord(word: String): Bool {
		if(checkAheadWord(word)) {
			incrementIndex(word.length);
			return true;
		}
		return false;
	}

	public function parsePossibleCharacter(char: String): Bool {
		if(currentChar() == char) {
			incrementIndex(1);
			return true;
		}
		return false;
	}

	public function parseWhitespace(): Bool {
		final start = index;
		while(content.isSpace(index)) {
			if(charCodeIsNewLine(charCodeAt(index))) {
				incrementLine();
			}
			if(incrementIndex(1)) {
				break;
			}
		}
		return start != index;
	}

	public function parseWhitespaceOrComments(): Bool {
		final start = index;
		while(index < content.length) {
			final preParseIndex = index;
			parseWhitespace();
			parseMultilineComment();
			parseComment();
			if(preParseIndex == index) {
				break;
			}
		}
		return start != index;
	}

	public function incrementIndex(amount: Int): Bool {
		index += amount;
		if(index >= content.length) {
			ended = true;
			return true;
		}
		return false;
	}

	public function parseContentUntilSemiNewLineOrComment(): String {
		return parseContentUntilCharOrNewLine(";");
	}

	public function parseContentUntilCharOrNewLine(c: String): String {
		hitCharFlag = false;
		var result = "";
		var isComment = false;
		final multiExists = multilineCommentOperatorStart.length > 0;
		final singleExists = singleCommentOperator.length > 0;
		while(index < content.length) {
			final char = charAt(index);
			if(char == "\n" || char == "\r") {
				break;
			}
			if(!isComment) {
				if(char == c) {
					hitCharFlag = true;
					break;
				}
			}
			if(multiExists && char == multilineCommentOperatorStart.charAt(0) && checkAhead(multilineCommentOperatorStart)) {
				if(!parseMultilineComment()) {
					return result;
				}
				continue;
			} else if(singleExists && char == singleCommentOperator.charAt(0)) {
				if(checkAhead(singleCommentOperator)) {
					isComment = true;
				}
			}
			if(!isComment) {
				result += char;
			}
			if(incrementIndex(1)) {
				break;
			}
		}
		return result;
	}

	public function parseComment(): Bool {
		if(checkAhead(singleCommentOperator)) {
			while(index < content.length) {
				if(charCodeIsNewLine(charCodeAt(index))) {
					incrementLine();
					return true;
				}
				if(incrementIndex(1)) {
					break;
				}
			}
		}
		return false;
	}

	public function parseMultilineComment(): Bool {
		// If "true", that means multiline ended on same line.
		final start = multilineCommentOperatorStart;
		final end = multilineCommentOperatorEnd;
		if(start.length == 0 || end.length == 0) return true;
		var result = true;
		var finished = false;
		if(checkAhead(start)) {
			final endChar0 = end.charAt(0);
			incrementIndex(start.length);
			while(index < content.length) {
				final char = charAt(index);
				if(char == endChar0) {
					if(checkAhead(end)) {
						incrementIndex(end.length);
						finished = true;
						break;
					}
				} else if(char == "\n") {
					result = false;
					incrementLine();
				}
				if(incrementIndex(1)) {
					break;
				}
			}
		}
		return result;
	}

	function incrementLine() {
		lineNumber++;
		currLineIndex = index + 1;
	}
}
