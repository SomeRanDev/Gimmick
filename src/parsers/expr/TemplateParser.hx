package parsers.expr;

import ast.typing.TemplateArgument;

import parsers.Parser;
import parsers.Error;
import parsers.ErrorType;

import parsers.expr.TypeParser;

class TemplateParser {
	var parser: Parser;

	public function new(parser: Parser) {
		this.parser = parser;
	}

	public function parseTemplate(): Null<Array<TemplateArgument>> {
		parser.parseWhitespaceOrComments();
		if(!parser.parseNextContent("<")) return null;

		final result = [];

		var indexTracker = 0;
		var argTracker = 0;
		while(true) {
			parser.parseWhitespaceOrComments();

			indexTracker = parser.getIndex();
			argTracker = result.length;

			if(parser.parseNextContent(">")) {
				break;
			} else {

				final varNameStart = parser.getIndexFromLine();
				final name = parser.parseNextVarName();
				if(name == null) {
					Error.addError(ErrorType.ExpectedVariableName, parser, varNameStart);
					return null;
				}

				parser.parseWhitespaceOrComments();

				if(parser.parseNextContent(",")) {
					result.push(new TemplateArgument(name, null));
				} else {
					var describers = null;
					parser.parseWhitespaceOrComments();
					if(parser.parseNextContent(":")) {
						parser.parseWhitespaceOrComments();
						describers = parseGenericDescriber(parser);
						parser.parseWhitespaceOrComments();
					}
					var defaultType = if(parser.parseNextContent("=")) {
						parser.parseWhitespaceOrComments();
						parser.parseType();
					} else {
						null;
					}
					result.push(new TemplateArgument(name, describers, defaultType));
					parser.parseWhitespaceOrComments();
					if(parser.parseNextContent(",")) {
					}
				}
			}

			if(indexTracker != parser.getIndex() && argTracker == result.length) {
				Error.addError(ErrorType.UnexpectedCharacter, parser, parser.getIndexFromLine());
				return null;
			}
		}

		return result.length == 0 ? null : result;
	}

	public static function parseGenericDescriber(parser: Parser): Null<Array<TemplateArgumentRequirement>> {
		final word = parser.parseMultipleWords(["has", "extends", "matches"]);
		if(word != null) {
			parser.parseWhitespaceOrComments();
			switch(word) {
				case "has": {
					final result = parseSingleDescriber(parser);
					if(result != null) {
						return [ result ];
					}
					return null;
				}
				case "extends": {
					final start = parser.getIndexFromLine();
					final type = parser.parseType();
					if(type != null) {
						switch(type.type) {
							case Class(_, _): {}
							default: {
								Error.addError(ErrorType.MustUseClassTypeOnExtendsGenericDescriber, parser, start);
							}
						}
						return [ TemplateArgumentRequirement.Extends(type) ];
					} else {
						Error.addError(ErrorType.ExpectedType, parser, start);
					}
				}
				case "matches": {
					// TODO: parse template
				}
				default: {}
			}
		} else if(parser.parseNextContent("{")) {
			var result: Null<Array<TemplateArgumentRequirement>> = null;
			while(true) {
				parser.parseWhitespaceOrComments();
				final describer = parseGenericDescriber(parser);
				if(describer == null) {
					break;
				} else {
					if(result == null) {
						result = [];
					}
					for(d in describer) {
						result.push(d);
					}
				}
				parser.parseWhitespaceOrComments();
				if(parser.parseNextContent("}")) {
					break;
				} else if(!parser.parseNextContent(",")) {
					Error.addError(ErrorType.UnexpectedCharacterExpectedThisOrThat, parser, parser.getIndexFromLine(), 0, [",", "}"]);
					parser.incrementIndex(1);
				}
			}
			return result;
		}
		return null;
	}

	public static function parseSingleDescriber(parser: Parser): Null<TemplateArgumentRequirement> {
		final word = parser.parseMultipleWords(["var", "def", "attribute"]);
		if(word != null) {
			parser.parseWhitespaceOrComments();

			final varNameStart = parser.getIndexFromLine();
			final name = parser.parseNextVarName();
			if(name == null) {
				Error.addError(ErrorType.ExpectedVariableName, parser, varNameStart);
				return null;
			}

			parser.parseWhitespaceOrComments();

			switch(word) {
				case "var": {
					if(parser.parseNextContent(":")) {
						parser.parseWhitespaceOrComments();
						final type = parser.parseType();
						if(type != null) {
							return HasVariable(name, type);
						}
					} else {
						Error.addError(ErrorType.UnexpectedCharacter, parser, parser.getIndexFromLine());
					}
				}
				case "def": {
					final typeFunc = TypeParser.parseFunctionTypeData(parser);
					if(typeFunc != null) {
						return HasFunction(name, typeFunc);
					}
				}
				case "attribute": {
					return HasAttribute(name);
				}
				default: {}
			}
		}
		return null;
	}
}
