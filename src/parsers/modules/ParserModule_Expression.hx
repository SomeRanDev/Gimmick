package parsers.modules;

import ast.scope.ScopeMember;

import parsers.Error;
import parsers.ErrorType;
import parsers.modules.ParserModule;
using parsers.expr.Expression;
using parsers.expr.TypedExpression;
import parsers.expr.ExpressionParser;

import ast.scope.ExpressionMember;

class ParserModule_Expression extends ParserModule {
	public static var it = new ParserModule_Expression();

	public override function parse(parser: Parser): Null<Module> {
		var shouldParseEnd = true;
		var result: Null<ExpressionMember> = null;
		if(isPass(parser)) {
			result = Pass;
		} else if(isBreak(parser)) {
			result = Break;
		} else if(isContinue(parser)) {
			result = Continue;
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
				Error.addError(ErrorType.UnexpectedCharacter, parser, parser.getIndexFromLine());
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

	function getNextExpression(parser: Parser): Null<Expression> {
		parser.parseWhitespaceOrComments();
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
		final expr = getNextExpression(parser);//getNextTypedExpression(parser);
		if(expr != null) {
			return Basic(expr);
		}
		return null;
	}

	function isPass(parser: Parser): Bool {
		return parser.parseWord("pass");
	}

	function isBreak(parser: Parser): Bool {
		return parser.parseWord("break");
	}

	function isContinue(parser: Parser): Bool {
		return parser.parseWord("continue");
	}

	function isReturn(parser: Parser): Bool {
		return parser.parseWord("return");
	}

	function parseReturn(parser: Parser): Null<ExpressionMember> {
		final expr = getNextExpression(parser);//getNextTypedExpression(parser);
		if(expr != null) {
			return ReturnStatement(expr);
		}
		return null;
	}

	function isScope(parser: Parser): Bool {
		return parser.parseWord("scope");
	}

	function parseScope(parser: Parser): Null<ExpressionMember> {
		if(parser.parseNextContent(":")) {
			final members = parser.parseNextLevelContent();
			return Scope(members == null ? [] : members.members);
		} else {
			Error.addError(ErrorType.UnexpectedCharacterExpectedThis, parser, parser.getIndexFromLine(), 0, [":"]);
		}
		return null;
	}

	function isLoop(parser: Parser): Bool {
		return parser.checkAheadWord("loop") || parser.checkAheadWord("while") || parser.checkAheadWord("until");
	}

	function parseLoop(parser: Parser): Null<ExpressionMember> {
		final word = parser.parseMultipleWords(["loop", "while", "until"]);
		final startIndex = parser.getIndex();
		if(word != null) {
			var expr: Null<Expression> = null;
			if(word != "loop") {
				final startCond = parser.getIndexFromLine();
				expr = getNextExpression(parser);//getNextTypedExpression(parser);
				if(expr == null) {
					Error.addError(ErrorType.ExpectedCondition, parser, startCond);
					return null;
				}
			}
			if(parser.parseNextContent(":")) {
				final members = parser.parseNextLevelContent();
				return Loop(expr, members == null ? [] : members.members, word != "until");
			} else {
				Error.addError(ErrorType.UnexpectedCharacterExpectedThis, parser, parser.getIndexFromLine(), 0, [":"]);
			}
		}
		return null;
	}

	function isIf(parser: Parser): Bool {
		return parser.checkAheadWord("if") || parser.checkAheadWord("unless");
	}

	function parseIf(parser: Parser): Null<ExpressionMember> {
		final word = parser.parseMultipleWords(["if", "unless"]);
		final startIndex = parser.getIndex();
		if(word != null) {
			parser.parseWhitespaceOrComments();

			final startCond = parser.getIndexFromLine();
			final cond = getNextExpression(parser);//getNextTypedExpression(parser);
			if(cond == null) {
				Error.addError(ErrorType.ExpectedCondition, parser, startCond);
				return null;
			}

			parser.parseWhitespaceOrComments();

			var ifStatement: Null<ExpressionMember> = null;
			if(parser.parseNextContent(":")) {
				final members = parser.parseNextLevelContent();
				ifStatement = IfStatement(cond, members != null ? members.members : [], word == "if");
			} else {
				Error.addError(ErrorType.UnexpectedCharacterExpectedThis, parser, parser.getIndexFromLine(), 0, [":"]);
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
					final startCond = parser.getIndexFromLine();
					cond = getNextExpression(parser);//getNextTypedExpression(parser);
					if(cond == null) {
						Error.addError(ErrorType.ExpectedCondition, parser, startCond);
						return null;
					}
				}

				parser.parseWhitespaceOrComments();

				if(parser.parseNextContent(":")) {
					final memberScope = parser.parseNextLevelContent();
					final members = memberScope == null ? [] : memberScope.members;
					if(type == 0) {
						elseStatements = members;
						break;
					} else if(cond != null) {
						if(elseIfStatements == null && ifStatement != null) {
							elseIfStatements = [ifStatement];
						}
						elseIfStatements.push(IfStatement(cond, members, type == 1));
					}
				} else {
					Error.addError(ErrorType.UnexpectedCharacterExpectedThis, parser, parser.getIndexFromLine(), 0, [":"]);
					return null;
				}
			}


			if(elseIfStatements != null) {
				return IfElseIfChain(elseIfStatements, elseStatements);
			} else if(elseStatements != null && ifStatement != null) {
				return IfElseStatement(ifStatement, elseStatements);
			} else {
				return ifStatement;
			}
		}
		return null;
	}
}
