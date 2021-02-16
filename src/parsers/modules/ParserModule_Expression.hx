package parsers.modules;

import ast.scope.ScopeMember;

import parsers.error.Error;
import parsers.error.ErrorType;

import parsers.modules.ParserModule;

using parsers.expr.Expression;
using parsers.expr.TypedExpression;
import parsers.expr.ExpressionParser;
import parsers.expr.Position;

import ast.scope.ExpressionMember;

class ParserModule_Expression extends ParserModule {
	public static var it = new ParserModule_Expression();

	public override function parse(parser: Parser): Null<Module> {
		var shouldParseEnd = true;
		var result: Null<ExpressionMember> = null;
		final startIndex = parser.getIndex();
		if(isPass(parser)) {
			parser.parseWord("pass");
			result = new ExpressionMember(Pass, parser.makePosition(startIndex));
		} else if(isBreak(parser)) {
			parser.parseWord("break");
			result = new ExpressionMember(Break, parser.makePosition(startIndex));
		} else if(isContinue(parser)) {
			parser.parseWord("continue");
			result = new ExpressionMember(Continue, parser.makePosition(startIndex));
		} else if(isScope(parser)) {
			result = parseScope(parser);
		} else if(isReturn(parser)) {
			result = parseReturn(parser);
		} else if(isLoop(parser)) {
			result = parseLoop(parser);
			shouldParseEnd = false;
		} else if(isIf(parser)) {
			result = parseIf(parser);
			shouldParseEnd = false;
		} else {
			result = parseExpression(parser);
		}
		if(shouldParseEnd) {
			if(!parser.parseNextExpressionEnd()) {
				Error.addErrorAtChar(ErrorType.UnexpectedCharacter, parser);
				return Nothing;
			}
		}
		if(parser.isPreliminary()) {
			return Nothing;
		}
		if(result != null) {
			return Expression(result);
		}
		return null;
	}

	function getNextExpression(parser: Parser, sameLine: Bool = false): Null<Expression> {
		parser.parseWhitespaceOrComments(sameLine);
		if(sameLine && parser.currentChar() == "\n") {
			return null;
		}
		final result = parser.parseExpression();
		if(result != null) {
			return result;
		}
		return null;
	}

	function getNextTypedExpression(parser: Parser): Null<TypedExpression> {
		parser.parseWhitespaceOrComments();
		final result = parser.parseExpression();
		if(result != null) {
			final typed = result.getType(parser, Normal);
			if(typed != null) {
				return typed;
			}
		}
		return null;
	}

	function parseExpression(parser: Parser): Null<ExpressionMember> {
		final startIndex = parser.getIndex();
		final expr = getNextExpression(parser);//getNextTypedExpression(parser);
		if(expr != null) {
			return new ExpressionMember(Basic(expr), parser.makePosition(startIndex));
		}
		return null;
	}

	function isPass(parser: Parser): Bool {
		return parser.checkAheadWord("pass");
	}

	function isBreak(parser: Parser): Bool {
		return parser.checkAheadWord("break");
	}

	function isContinue(parser: Parser): Bool {
		return parser.checkAheadWord("continue");
	}

	function isReturn(parser: Parser): Bool {
		return parser.checkAheadWord("return");
	}

	function parseReturn(parser: Parser): Null<ExpressionMember> {
		final startIndex = parser.getIndex();
		parser.parseWord("return");
		final wordPos = parser.makePosition(startIndex);
		final expr = getNextExpression(parser, true);//getNextTypedExpression(parser);
		return new ExpressionMember(ReturnStatement(expr), parser.makePosition(startIndex), wordPos);
	}

	function isScope(parser: Parser): Bool {
		return parser.checkAheadWord("scope");
	}

	function parseScope(parser: Parser): Null<ExpressionMember> {
		final startIndex = parser.getIndex();
		parser.parseWord("scope");
		final scopePos = parser.makePosition(startIndex);
		if(parser.parseNextContent(":")) {
			final pos = parser.makePosition(startIndex);
			final members = parser.parseNextLevelContent();
			return new ExpressionMember(Scope(members == null ? [] : members.members), pos, scopePos);
		} else {
			Error.addError(ErrorType.UnexpectedCharacterExpectedThis, parser, parser.getIndex(), 0, [":"]);
		}
		return null;
	}

	function isLoop(parser: Parser): Bool {
		return parser.checkAheadWord("loop") || parser.checkAheadWord("while") || parser.checkAheadWord("until");
	}

	function parseLoop(parser: Parser): Null<ExpressionMember> {
		final startIndex = parser.getIndex();
		final word = parser.parseMultipleWords(["loop", "while", "until"]);
		final wordPos = parser.makePosition(startIndex);
		if(word != null) {
			var expr: Null<Expression> = null;
			if(word != "loop") {
				final startCond = parser.getIndex();
				expr = getNextExpression(parser);//getNextTypedExpression(parser);
				if(expr == null) {
					Error.addError(ErrorType.ExpectedCondition, parser, startCond);
					return null;
				}
			}
			if(parser.parseNextContent(":")) {
				final pos = parser.makePosition(startIndex);
				final members = parser.parseNextLevelContent();
				return new ExpressionMember(Loop(expr, members == null ? [] : members.members, word != "until"), pos, wordPos);
			} else {
				Error.addError(ErrorType.UnexpectedCharacterExpectedThis, parser, parser.getIndex(), 0, [":"]);
			}
		}
		return null;
	}

	function isIf(parser: Parser): Bool {
		return parser.checkAheadWord("if") || parser.checkAheadWord("unless");
	}

	function parseIf(parser: Parser): Null<ExpressionMember> {
		final startIndex = parser.getIndex();
		final word = parser.parseMultipleWords(["if", "unless"]);
		final wordPos = parser.makePosition(startIndex);
		if(word != null) {
			parser.parseWhitespaceOrComments();

			final startCond = parser.getIndex();
			final cond = getNextExpression(parser);//getNextTypedExpression(parser);
			if(cond == null) {
				Error.addError(ErrorType.ExpectedCondition, parser, startCond);
				return null;
			}

			parser.parseWhitespaceOrComments();

			var ifStatement: Null<ExpressionMember> = null;
			if(parser.parseNextContent(":")) {
				final pos = parser.makePosition(startIndex);
				final members = parser.parseNextLevelContent();
				ifStatement = new ExpressionMember(IfStatement(cond, members != null ? members.members : [], word == "if"), pos, wordPos);
			} else {
				Error.addError(ErrorType.UnexpectedCharacterExpectedThis, parser, parser.getIndex(), 0, [":"]);
				return null;
			}

			parser.parseWhitespaceOrComments();

			var elseIfStatements: Null<Array<ExpressionMember>> = null;
			var elseStatements: Null<Array<ScopeMember>> = null;
			while(true) {
				final word = parser.parseMultipleWords(["else", "elif", "eless"]);
				if(word == null) {
					break;
				}
				var type = 0;
				if(word == "else") {
					parser.parseWhitespaceOrComments();
					final word2 = parser.parseMultipleWords(["if", "unless"]);
					if(word2 != null) {
						type = word2 == "if" ? 1 : 2;
					}
				} else if(word == "elif") {
					type = 1;
				} else if(word == "eless") {
					type = 2;
				}

				parser.parseWhitespaceOrComments();

				var cond: Null<Expression> = null;
				if(type != 0) {
					final startCond = parser.getIndex();
					cond = getNextExpression(parser);//getNextTypedExpression(parser);
					if(cond == null) {
						Error.addError(ErrorType.ExpectedCondition, parser, startCond);
						return null;
					}
				}

				parser.parseWhitespaceOrComments();

				if(parser.parseNextContent(":")) {
					final pos = parser.makePosition(startIndex);
					final memberScope = parser.parseNextLevelContent();
					final members = memberScope == null ? [] : memberScope.members;
					if(type == 0) {
						elseStatements = members;
						break;
					} else if(cond != null) {
						if(elseIfStatements == null && ifStatement != null) {
							elseIfStatements = [ifStatement];
						}
						elseIfStatements.push(new ExpressionMember(IfStatement(cond, members, type == 1), pos));
					}
				} else {
					Error.addError(ErrorType.UnexpectedCharacterExpectedThis, parser, parser.getIndex(), 0, [":"]);
					return null;
				}
			}


			if(elseIfStatements != null) {
				return new ExpressionMember(IfElseIfChain(elseIfStatements, elseStatements), Position.BLANK);
			} else if(elseStatements != null && ifStatement != null) {
				return new ExpressionMember(IfElseStatement(ifStatement, elseStatements), Position.BLANK);
			} else {
				return ifStatement;
			}
		}
		return null;
	}
}
