package parsers.modules;

import basic.Ref;

import ast.scope.Scope;

import parsers.error.Error;
import parsers.error.ErrorType;
import parsers.modules.ParserModule;

class ParserModule_Namespace extends ParserModule {
	public static var it = new ParserModule_Namespace();

	public override function parse(parser: Parser): Null<Module> {
		final startState = parser.saveParserState();
		final word = parser.parseMultipleWords(["start", "end"]);
		if(word != null) {
			final startOfModule = parser.getIndex() - word.length;
			parser.parseWhitespaceOrComments();
			if(parser.parseWord("namespace")) {
				if(word == "start") {
					parser.parseWhitespaceOrComments();

					final nameStart = parser.getIndex();
					final names = parser.parseDotConnectedVarNames();
					if(names == null) {
						Error.addError(ErrorType.ExpectedNamespaceName, parser, nameStart);
						return Nothing;
					}

					if(!parser.parseNextExpressionEnd()) {
						Error.addErrorAtChar(ErrorType.UnexpectedCharacter, parser);
						return Nothing;
					}

					return NamespaceStart(names);
				} else if(word == "end") {
					if(!parser.scope.namespacesExist()) {
						Error.addError(ErrorType.NoNamespaceToEnd, parser, startOfModule);
						return Nothing;
					}
					if(!parser.parseNextExpressionEnd()) {
						Error.addErrorAtChar(ErrorType.UnexpectedCharacter, parser);
						return Nothing;
					}
					return NamespaceEnd;
				}
			}
		}

		parser.restoreParserState(startState);

		return null;
	}
}
