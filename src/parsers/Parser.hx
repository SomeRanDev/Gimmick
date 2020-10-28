package parsers;

using StringTools;

import haxe.ds.GenericStack;

import io.SourceFileManager;

import ast.SourceFile;
import ast.scope.Scope;
import ast.scope.ScopeMember;
import ast.scope.ScopeMemberCollection;
import ast.typing.Type;

import parsers.Error;
import parsers.ErrorType;
import parsers.ParserLevel;
import parsers.ParserMode;

import parsers.expr.Literal;
import parsers.expr.Expression;
import parsers.expr.ExpressionParser;
import parsers.expr.LiteralParser;
import parsers.expr.TypeParser;
import parsers.expr.Position;

import parsers.modules.Module;
import parsers.modules.ParserModule;
import parsers.modules.ParserModule_Import;
import parsers.modules.ParserModule_Variable;
import parsers.modules.ParserModule_Expression;
import parsers.modules.ParserModule_Namespace;
import parsers.modules.ParserModule_Function;
import parsers.modules.ParserModule_Attribute;
import parsers.modules.ParserModule_Modify;

class Parser {
	public var content(default, null): String;
	public var manager(default, null): SourceFileManager;
	public var index(default, null): Int;
	public var lineNumber(default, null): Int;
	public var ended(default, null): Bool;

	public var scope(default, null): Scope;

	public var hitCharFlag(default, null): Bool;
	public var lastWordParsed(default, null): String;

	var levels: Array<ParserLevel>;
	var lineIndent: String;

	var moduleParsers: Array<ParserModule>;
	var modules: Array<Module>;

	var file: SourceFile;
	var currLineIndex: Int;
	var preliminary: Bool;
	var touchedContentOnThisLine: Bool;

	public static final singleCommentOperator = "#";
	public static final multilineCommentOperatorStart = "###";
	public static final multilineCommentOperatorEnd = "###";

	public function new(content: String, manager: SourceFileManager, file: SourceFile, preliminary: Bool) {
		this.content = content;
		this.manager = manager;
		index = 0;
		lineNumber = 1;
		ended = false;

		scope = new Scope(file);
		scope.push();

		hitCharFlag = false;
		lastWordParsed = "";

		levels = [];
		lineIndent = "";
		moduleParsers = [];
		modules = [];
		this.file = file;
		currLineIndex = 0;
		this.preliminary = preliminary;
		touchedContentOnThisLine = false;
	}

	public function beginParse() {
		while(true) {
			final oldIndex = index;
			parse();
			if(indexOutsideParser()) {
				break;
			}
			if(oldIndex == index) {
				Error.addError(UnexpectedContent, this, getIndexFromLine());
				break;
			}
		}
		endParse();
	}

	public function parseUntilLevelEnd(): Array<Module> {
		final oldModules = modules;
		modules = [];
		while(true) {
			final oldIndex = index;
			if(parse()) {
				break;
			}
			if(indexOutsideParser()) {
				break;
			}
			if(oldIndex == index) {
				Error.addError(UnexpectedContent, this, getIndexFromLine());
				break;
			}
		}
		final result = modules;
		modules = oldModules;
		return result;
	}

	function parse(): Bool {
		parseWhitespaceOrComments();
		if(checkIndentation()) {
			return true;
		}
		for(mod in moduleParsers) {
			final module = mod.parse(this);
			if(module != null) {
				modules.push(module);
				onModuleAdd(module);
				break;
			}
		}
		return false;
	}

	function checkIndentation(): Bool {
		if(levels.length > 1) {
			final first = levels[levels.length - 1];
			if(first != null) {
				if(first.popOnNewline != null) {
					if(first.popOnNewline != lineNumber) {
						return true;
					} else {
						return false;
					}
				}
			}

			final indents = [];
			var curr = "";
			for(i in 0...levels.length) {
				curr += levels[i].spacing;
				indents.push(curr);
			}

			var newLevel = -1;
			for(j in 0...indents.length) {
				final i = indents.length - j - 1;
				if(indents[i] == lineIndent) {
					newLevel = i;
				}
			}

			if(newLevel == -1) {
				Error.addError(ErrorType.InconsistentIndent, this, 0);
			} else if(newLevel < indents.length - 1) {
				return true;
			}
		}
		return false;
	}

	function onModuleAdd(module: Module) {
		updateScope(module);
	}

	function updateScope(module: Module) {
		switch(module) {
			case Variable(variable): {
				scope.addMember(new ScopeMember(Variable(variable.getRef())));
			}
			case Function(func): {
				scope.addMember(new ScopeMember(Function(func.getRef())));
			}
			case GetSet(getset): {
				scope.addMember(new ScopeMember(GetSet(getset.getRef())));
			}
			case NamespaceStart(names): {
				scope.pushMutlipleNamespaces(names);
			}
			case NamespaceEnd: {
				scope.popNamespace();
			}
			case Expression(exprMember): {
				scope.addExpressionMember(exprMember);
			}
			case Import(_, func): {
				if(func != null && func.get().callCount == 0) {
					scope.addFunctionCallExpression(func, this);
				}
			}
			case Attribute(attr): {
				scope.addAttribute(attr);
			}
			case AttributeInstance(attr, params, pos): {
				if(attr.compiler) {
					scope.addMember(new ScopeMember(CompilerAttribute(attr, params, pos)));
				} else {
					scope.addAttributeInstance(module);
				}
			}
			default: {}
		}
	}

	function endParse() {
		scope.popAllNamespaces();
		//scope.commitMainFunction();
	}

	function indexOutsideParser(): Bool {
		return index >= content.length;
	}

	public function getIndex(): Int {
		return index;
	}

	public function setIndex(i: Int) {
		index = i;
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

	public function getContent(): String {
		return content;
	}

	public function getContentLength(): Int {
		return content.length;
	}

	public function makePosition(start: Int) {
		return new Position(file, lineNumber, start, index);
	}

	public function makePositionEx(line: Int, start: Int, end: Int) {
		return new Position(file, line, start, end);
	}

	public function emptyPosition() {
		return new Position(file, 0, 0, 0);
	}

	public function isPreliminary(): Bool {
		return preliminary;
	}

	// ======================================================
	// * Modes
	// ======================================================

	public function getModules() {
		return modules;
	}

	public function setupForSourceFile() {
		pushLevel(getMode_SourceFile());
	}

	public function pushLevel(moduleParsers: Array<ParserModule>): Bool {
		var currLevel = "";
		for(l in levels) {
			currLevel += l.spacing;
		}
		if((lineIndent.length == 0 && currLevel.length == 0) || lineIndent.length > currLevel.length) {
			pushLevelInternal(moduleParsers, lineIndent.substring(currLevel.length), null);
			return true;
		}
		return false;
	}

	public function pushLevelOnSameLine(moduleParsers: Array<ParserModule>) {
		pushLevelInternal(moduleParsers, "", lineNumber);
	}

	function pushLevelInternal(moduleParsers: Array<ParserModule>, indent: String, popOnNewline: Null<Int>) {
		levels.push(new ParserLevel(moduleParsers, indent, popOnNewline));
		this.moduleParsers = moduleParsers;
	}

	public function popLevel(): Bool {
		if(levels.length > 1) {
			levels.pop();
			final first = levels[levels.length - 1];
			if(first != null) {
				moduleParsers = first.parsers;
			}
			return true;
		}
		return false;
	}

	public function getMode_SourceFile(): Array<ParserModule> {
		return [
			ParserModule_Attribute.it,
			ParserModule_Import.it,
			ParserModule_Namespace.it,
			ParserModule_Function.it,
			ParserModule_Variable.it,
			ParserModule_Modify.it,
			ParserModule_Expression.it
		];
	}

	public function getMode_Function(): Array<ParserModule> {
		return [
			ParserModule_Attribute.it,
			ParserModule_Function.it,
			ParserModule_Variable.it,
			ParserModule_Expression.it
		];
	}

	public function getMode_CompilerAttribute(): Array<ParserModule> {
		return [
			ParserModule_Function.it
		];
	}

	public function getMode_Modify(): Array<ParserModule> {
		return [
			ParserModule_Function.it
		];
	}

	// ======================================================
	// * Meta
	// ======================================================

	public function onTypeUsed(type: Type, header: Bool = false) {
		file.onTypeUsed(type, header);
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

	public function charCodeIsNewLine(code: Null<Int>): Bool {
		return code == 10;
	}

	public function checkAhead(check: String): Bool {
		final end = index + check.length;
		if(end > content.length) return false;
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

	public function isNumberChar(c: Null<Int>): Bool {
		return c != null && (c >= 48 && c <= 57);
	}

	public function isDecimalNumberChar(c: Null<Int>): Bool {
		return isNumberChar(c) || c == 95;
	}

	public function isHexNumberChar(c: Null<Int>): Bool {
		return isNumberChar(c) || (c >= 65 && c <= 70) || (c >= 97 && c <= 102) || c == 95;
	}

	public function isBinaryNumberChar(c: Null<Int>): Bool {
		return c == 48 || c == 49 || c == 95;
	}

	public function isNameChar(c: Int): Bool {
		return isNumberChar(c) || isNameCharStarter(c);
	}

	public function parseNextContent(content: String): Bool {
		if(checkAhead(content)) {
			incrementIndex(content.length);
			return true;
		}
		return false;
	}

	@:nullSafety(Off)
	public function parseNextVarName(): Null<String> {
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
		return result;
	}

	public function parseDotConnectedVarNames(): Null<Array<String>> {
		final result = [];
		var name = null;
		do {
			name = parseNextVarName();
			if(name != null) {
				result.push(name);
			} else {
				break;
			}
			if(!parseNextContent(".")) {
				break;
			}
		} while(name != null);
		return result.length == 0 ? null : result;
	}

	public function parseNextLiteral(): Null<Literal> {
		final literalParser = new LiteralParser(this);
		return literalParser.parseLiteral();
	}

	public function parseExpression(): Null<Expression> {
		final start = getIndex();
		final exprParser = new ExpressionParser(this);
		if(exprParser.successful()) {
			return exprParser.buildExpression();
		}
		return null;
	}

	public function parseType(): Null<Type> {
		final typeParser = new TypeParser(this);
		return typeParser.parseType();
	}

	public function parseWord(word: String): Bool {
		if(checkAheadWord(word)) {
			incrementIndex(word.length);
			return true;
		}
		return false;
	}

	public function parseMultipleWords(words: Array<String>): Null<String> {
		for(word in words) {
			if(parseWord(word)) {
				lastWordParsed = word;
				return word;
			}
		}
		return null;
	}

	public function parsePossibleCharacter(char: String): Bool {
		if(currentChar() == char) {
			incrementIndex(1);
			return true;
		}
		return false;
	}

	public function parseNextExpressionEnd(): Bool {
		parseWhitespaceOrComments(true);
		if(parseNextContent(";")) {
			return true;
		}
		return charCodeIsNewLine(currentCharCode()) || touchedContentOnThisLine;
	}

	public function parseNextLevelContent(mode: ParserMode = Function): Null<ScopeMemberCollection> {
		final modules: Array<ParserModule> = switch(mode) {
			case SourceFile: getMode_SourceFile();
			case Function: getMode_Function();
			case CompilerAttribute: getMode_CompilerAttribute();
			case Modify: getMode_Modify();
		}
		final currLine = getLineNumber();
		parseWhitespaceOrComments();
		var successful = true;
		if(currLine != getLineNumber()) {
			successful = pushLevel(modules);
		} else {
			pushLevelOnSameLine(modules);
		}
		if(successful) {
			scope.push();
			final functionModules = parseUntilLevelEnd();
			popLevel();
			return scope.pop();
		} else {
			return new ScopeMemberCollection();
		}
	}

	public function parseWhitespace(untilNewline: Bool = false): Bool {
		final start = index;
		var hitNewLine = false;
		while(content.isSpace(index)) {
			if(charCodeIsNewLine(charCodeAt(index))) {
				if(untilNewline) {
					return true;
				}
				touchedContentOnThisLine = false;
				lineIndent = "";
				hitNewLine = true;
				incrementLine();
			} else if(hitNewLine) {
				lineIndent += currentChar();
			}
			if(incrementIndex(1)) {
				break;
			}
		}
		return start != index;
	}

	public function parseWhitespaceOrComments(untilNewline: Bool = false): Bool {
		final start = index;
		while(index < content.length) {
			final preParseIndex = index;
			parseWhitespace(untilNewline);
			parseMultilineComment();
			parseComment();
			if(preParseIndex == index) {
				break;
			}
		}
		return start != index;
	}

	public function incrementIndex(amount: Int, incrementedSpace: Bool = false): Bool {
		index += amount;
		if(!incrementedSpace) {
			touchedContentOnThisLine = true;
		}
		if(index >= content.length) {
			ended = true;
			return true;
		}
		return false;
	}

	public function parseContentUntilChar(c: Array<String>): String {
		return parseContentUntilCharOrNewLine(c, false);
	}

	public function parseContentUntilSemiNewLineOrComment(): String {
		return parseContentUntilCharOrNewLine([";"]);
	}

	public function parseContentUntilCharOrNewLine(c: Array<String>, newline: Bool = true): String {
		hitCharFlag = false;
		var result = "";
		var isComment = false;
		final multiExists = multilineCommentOperatorStart.length > 0;
		final singleExists = singleCommentOperator.length > 0;
		while(index < content.length) {
			final char = charAt(index);
			if(newline && (char == "\n" || char == "\r")) {
				break;
			}
			if(!isComment) {
				if(char != null && c.contains(char)) {
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
			if(!isComment && char != null) {
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
			var foundNewline = false;
			while(index < content.length) {
				if(charCodeIsNewLine(charCodeAt(index))) {
					incrementLine();
					foundNewline = true;
				}
				if(incrementIndex(1)) {
					break;
				}
				if(foundNewline) {
					return true;
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
		if(parseNextContent(start)) {
			final endChar0 = end.charAt(0);
			while(index < content.length) {
				final char = charAt(index);
				if(char == endChar0) {
					if(parseNextContent(end)) {
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

	public function incrementLine() {
		lineNumber++;
		currLineIndex = index + 1;
	}
}
