package parsers;

using StringTools;

import parsers.Parser;
import parsers.ErrorType;

class Error {
	public var errorType(default, null): ErrorType;
	public var lineStr(default, null): String;
	public var file(default, null): String;
	public var line(default, null): Int;
	public var start(default, null): Int;
	public var end(default, null): Int;

	static var errors: Array<Error> = [];

	public function new(errorType: ErrorType, lineStr: String, file: String, line: Int, start: Int, end: Int) {
		this.errorType = errorType;
		this.lineStr = lineStr;
		this.file = file;
		this.line = line;
		this.start = start;
		this.end = end;
	}

	function errorDescLine(): String {
		return "\"" + file + "\" - Line #" + line + " (" + start + ", " + end + "):";
	}

	public function toString(): String {
		final msg = errorType.getErrorMessage();
		var result = "\n";
		result += msg + "\n";
		result += repeatChar("-", msg.length) + "\n";
		result += errorDescLine() + "\n";
		result += lineStr + "\n";
		return result;
	}

	public static function addError(errorType: ErrorType, parser: Parser, start: Int) {
		final lineNumber = parser.getLineNumber();
		final lineStr = findLine(parser.content, lineNumber);
		final end = parser.getIndexFromLine();
		final errorLineString = formatLineString(lineStr, lineNumber, start, end, errorType);
		final error = new Error(errorType, errorLineString, parser.getRelativePath(), lineNumber, start, end);
		errors.push(error);
	}

	static function findLine(content: String, lineNumber: Int): String {
		var result = "";
		var saveLine = false;
		var currLine = 1;
		var currIndex = 0;
		while(currIndex < content.length) {
			if(content.fastCodeAt(currIndex) == 10) {
				currLine++;
				if(saveLine) {
					return result;
				} else if(currLine == lineNumber) {
					saveLine = true;
				}
			} else if(saveLine) {
				result += content.charAt(currIndex);
			}
			currIndex++;
		}
		return result;
	}

	static function formatLineString(line: String, lineNumber: Int, start: Int, end: Int, err: ErrorType): String {
		final lineNumberOffset = Std.string(lineNumber).length + 1;

		var result = "";
		result += repeatChar(" ", lineNumberOffset) + "|\n";

		result += "" + lineNumber + " | ";
		result += line + "\n";

		result += repeatChar(" ", lineNumberOffset) + "| ";
		result += repeatChar(" ", start) + repeatChar("^", end - start);
		result += " " + err.getErrorLabel() + "\n";

		return result;
	}

	static function repeatChar(str: String, amount: Int): String {
		var result = str;
		for(i in 1...amount) result += str;
		return result;
	}

	public static function printAllErrors() {
		for(e in errors) {
			final output = e.toString();
			haxe.Log.trace(output + "\n", null);
		}
	}

	public static function hasErrors(): Bool {
		return errors.length != 0;
	}
}
