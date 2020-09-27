package parsers;

using StringTools;

import io.SourceFileManager;

import ast.SourceFile;

import parsers.modules.ParserModule;
import parsers.modules.ParserModule_Import;

class Parser {
	public var content(default, null): String;
	public var manager(default, null): SourceFileManager;
	public var index(default, null): Int;
	public var lineNumber(default, null): Int;
	public var ended(default, null): Bool;

	var modules: Array<ParserModule>;
	var file: SourceFile;
	var currLineIndex: Int;

	public static final singleCommentOperator = "#";
	public static final multilineCommentOperatorStart = "###";
	public static final multilineCommentOperatorEnd = "###";

	public function new(content: String, manager: SourceFileManager, file: SourceFile) {
		this.content = content;
		this.manager = manager;
		index = 0;
		lineNumber = 1;
		ended = false;
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
			ParserModule_Import.it
		];
	}

	// ======================================================
	// * Tools
	// ======================================================

	public function currentChar(): Null<String> {
		return charAt(index);
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

	public function isNameChar(c: Int): Bool {
		return (c >= 48 && c <= 57) || (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c == 95;
	}

	public function parseWord(word: String): Bool {
		if(checkAheadWord(word)) {
			incrementIndex(word.length);
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
