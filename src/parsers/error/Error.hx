package parsers.error;

using StringTools;

import basic.Ref;
import basic.Tuple2;

import parsers.Parser;
import parsers.error.ErrorType;
import parsers.error.ErrorPromise;

import parsers.expr.Position;

class TabReformatResult {
	public var line: String;
	public var start: Int;
	public var end: Int;

	public function new(line: String, start: Int, end: Int) {
		this.line = line;
		this.start = start;
		this.end = end;
	}
}

class LineCacheData {
	public var line: String;
	public var indexStart: Int;

	public function new(line: String, indexStart: Int) {
		this.line = line;
		this.indexStart = indexStart;
	}
}

class Error {
	var errorString: String;

	static var errors: Array<Error> = [];
	static var promises: Map<String, Array<ErrorPromise>> = [];
	static var lineCache: Map<String, Array<LineCacheData>> = [];

	public function new(errorString: String) {
		this.errorString = errorString;
	}

	public function toString(): String {
		return errorString;
	}

	public static function addError(errorType: ErrorType, parser: Parser, start: Int, endOffset: Int = 0, params: Null<Array<String>> = null) {
		addErrorWithStartEnd(errorType, parser, start, parser.getIndex() + endOffset, params);
	}

	public static function addErrorAtChar(errorType: ErrorType, parser: Parser) {
		addError(errorType, parser, parser.getIndex());
	}

	public static function addErrorWithStartEnd(errorType: ErrorType, parser: Parser, start: Int, end: Int, params: Null<Array<String>> = null) {
		addErrorFromData(errorType, parser.content, parser.getRelativePath(), start, end, params);
	}

	public static function addErrorFromPos(errorType: ErrorType, position: Position, params: Null<Array<String>> = null) {
		addErrorFromData(errorType, position.file.source, position.file.pathInfo.relativePath, position.startIndex, position.endIndex, params);
	}

	public static function addErrorFromData(errorType: ErrorType, content: String, path: String, start: Int, end: Int, params: Null<Array<String>>) {
		final data = getContentData(content, path);
		while(end > start && StringTools.isSpace(content, end - 1)) {
			end--;
		}
		if(data != null) {
			final lines = findStartEndLines(data, start, end);
			final lineStart = start - data[lines.a].indexStart;
			final lineEnd = end - data[lines.b].indexStart;
			if(lines.a == lines.b) {
				final errorString = formatSingleLineString(data[lines.a].line, lines.a + 1, lineStart, lineEnd, errorType, params);
				final errorDesc = errorDescSingleLine(path, lines.a + 1, lineStart, lineEnd);
				errors.push(new Error(formatErrorOutput(errorString, errorDesc, errorType, params)));
			} else if(lines.a < lines.b) {
				final errorString = formatMultiLineString(data, lines.a, lines.b, start, end, errorType, params);
				final errorDesc = errorDescSingleLine(path, lines.a + 1, lineStart, lineEnd);
				errors.push(new Error(formatErrorOutput(errorString, errorDesc, errorType, params)));
			}
		}
	}

	static function findStartEndLines(data: Array<LineCacheData>, start: Int, end: Int): Tuple2<Int, Int> {
		var startLine = -1;
		var endLine = -1;
		for(i in 0...data.length) {
			final curr = data[i];
			if(startLine == -1 && curr.indexStart > start) {
				startLine = i - 1;
			}
			if(endLine == -1 && curr.indexStart > end) {
				endLine = i - 1;
			}
		}
		if(startLine == -1) startLine = data.length - 1;
		if(endLine == -1) endLine = data.length - 1;
		return new Tuple2(startLine, endLine);
	}

	static function getContentData(content: String, path: String): Null<Array<LineCacheData>> {
		if(!lineCache.exists(path)) {
			final result: Array<LineCacheData> = [];

			var lineText = "";
			var currLine = 1;
			var currIndex = 0;
			var lineStart = 0;
			while(currIndex < content.length) {
				if(content.fastCodeAt(currIndex) == 10) {
					currLine++;
					result.push(new LineCacheData(lineText, lineStart));
					lineText = "";
					lineStart = currIndex + 1;
				} else {
					lineText += content.charAt(currIndex);
				}
				currIndex++;
			}

			result.push(new LineCacheData(lineText, lineStart));
			lineCache.set(path, result);
			return result;
		}

		return lineCache.get(path);
	}

	static function findLine(content: String, lineNumber: Int, lineStartIndex: Null<Ref<Int>> = null): String {
		var result = "";
		var saveLine = false;
		var currLine = 1;
		var currIndex = 0;
		var lineStart = 0;
		while(currIndex < content.length) {
			if(content.fastCodeAt(currIndex) == 10) {
				currLine++;
				if(saveLine) {
					if(lineStartIndex != null) lineStartIndex.set(lineStart);
					return result;
				} else if(currLine == lineNumber) {
					saveLine = true;
				}
				lineStart = currIndex;
			} else if(saveLine) {
				result += content.charAt(currIndex);
			}
			currIndex++;
		}
		if(lineStartIndex != null) lineStartIndex.set(lineStart);
		return result;
	}

	static function formatErrorOutput(errorContent: String, errorDesc: String, errorType: ErrorType, params: Null<Array<String>>): String {
		final msg = formatString(errorType.getErrorMessage(), params);
		var result = "";
		result += msg + "\n";
		result += repeatChar("-", msg.length) + "\n";
		result += errorDesc + "\n";
		result += errorContent;
		return result;
	}

	static function errorDescSingleLine(file: String, line: Int, start: Int, end: Int): String {
		return "\"" + file + "\" - Line #" + line + " (" + start + ", " + end + "):";
	}

	static function formatSingleLineString(line: String, lineNumber: Int, start: Int, end: Int, err: ErrorType, params: Null<Array<String>>): String {
		final lineNumberOffset = Std.string(lineNumber).length + 1;

		final tabSize = 4;
		final result = reformatTabs(line, tabSize, start, end);
		final formattedLine = result.line;
		final difference = formattedLine.length - line.length;
		start = result.start;
		end = result.end;

		var result = "";
		result += repeatChar(" ", lineNumberOffset) + "|\n";

		result += "" + lineNumber + " | ";
		result += formattedLine.rtrim() + "\n";

		result += repeatChar(" ", lineNumberOffset) + "| ";
		result += repeatChar(" ", start) + repeatChar("^", Std.int(Math.max(1, end - start)));
		result += " " + formatString(err.getErrorLabel(), params) + "\n";

		return result;
	}

	static function formatMultiLineString(data: Array<LineCacheData>, startLine: Int, endLine: Int, startIndex: Int, endIndex: Int, err: ErrorType, params: Null<Array<String>>): String {
		final lineNumberOffset = Std.string((startLine + 1)).length + 1;

		final startLineData = data[startLine];
		final endLineData = data[endLine];

		final lineStartIndex = startIndex - startLineData.indexStart;
		final lineEndIndex = endIndex - endLineData.indexStart;

		final tabSize = 4;

		var result = "";
		result += repeatChar(" ", lineNumberOffset) + "|\n";

		var first = true;
		var tabResult: Null<TabReformatResult> = null;
		for(i in startLine...endLine + 1) {
			final lineData = data[i];
			final index = first ? lineStartIndex : (i == endLine ? lineEndIndex : 0);
			tabResult = reformatTabs(lineData.line, tabSize, index == 0 ? 0 : index, index == 0 ? lineData.line.length - 1 : index + 1);
			final formattedLine = tabResult.line;

			result += "" + (i + 1) + " | " + (first ? " " : "|");
			result += formattedLine.rtrim() + "\n";

			if(first) {
				result += repeatChar(" ", lineNumberOffset) + "|";
				result += "  " + repeatChar("_", tabResult.start) + repeatChar("^", 1) + "\n";
				first = false;
			}
		}

		result += repeatChar(" ", lineNumberOffset) + "| ";
		result += "|" + repeatChar("_", tabResult.start - 1) + repeatChar("^", 1);
		result += " " + formatString(err.getErrorLabel(), params) + "\n";

		return result;
	}

	static function reformatTabs(input: String, tabSize: Int, start: Int, end: Int): TabReformatResult {
		final tabReplacement = repeatChar(" ", tabSize);
		var result = "";
		var startResult = start;
		var endResult = end;
		for(i in 0...input.length) {
			final char = input.charAt(i);
			if(i < end && char == "\t") {
				if(i < start) {
					startResult += tabSize - 1;
				}
				endResult += tabSize - 1;
				result += tabReplacement;
			} else {
				result += char;
			}
		}
		return new TabReformatResult(result, startResult, endResult);
	}

	static function repeatChar(str: String, amount: Int): String {
		if(amount == 0) return "";
		var result = str;
		for(i in 1...amount) result += str;
		return result;
	}

	public static function printAllErrors() {
		haxe.Log.trace(errors.map(e -> e.toString()).join("\n"), null);
	}

	public static function hasErrors(): Bool {
		return errors.length != 0;
	}

	public static function errorCount(): Int {
		return errors.length;
	}

	static function formatString(str: String, params: Null<Array<String>>): String {
		if(params != null) {
			var index = 1;
			var result = str;
			for(p in params) {
				result = result.replace("%" + Std.string(index++), p);
			}
			return result;
		}
		return str;
	}

	public static function addErrorPromise(key: String, promise: ErrorPromise) {
		@:nullSafety(Off) {
			if(!promises.exists(key)) {
				promises.set(key, []);
			}
			promises.get(key).push(promise);
		}
	}

	public static function clearErrorPromise(key: String) {
		promises.set(key, []);
	}

	public static function addErrorPromiseDirect(key: String, errorType: ErrorType, params: Array<String>, index: Null<Int> = null) {
		addErrorPromise(key, new ErrorPromiseBase(errorType, params, index));
	}

	public static function completePromiseOne(key: String, position: Position): Bool {
		@:nullSafety(Off) {
			var result = false;
			if(promises.exists(key)) {
				for(promise in promises.get(key)) {
					promise.completeOne(position);
				}
				result = promises.get(key).length > 0;
			}
			clearErrorPromise(key);
			return result;
		}
	}

	public static function completePromiseMulti(key: String, positions: Array<Position>): Bool {
		@:nullSafety(Off) {
			var result = false;
			if(promises.exists(key)) {
				for(promise in promises.get(key)) {
					promise.completeMulti(positions);
				}
				result = promises.get(key).length > 0;
			}
			clearErrorPromise(key);
			return result;
		}
	}
}
