package parsers.modules;

import basic.Ref;

import ast.scope.Scope;

import parsers.Error;
import parsers.ErrorType;
import parsers.modules.ParserModule;

class ParserModule_Namespace extends ParserModule {
	public static var it = new ParserModule_Namespace();

	public override function parse(parser: Parser): Null<Module> {
		final index = parser.getIndex();
		final word = parser.parseMultipleWords(["start", "end"]);
		if(word != null) {
			final startOfModule = parser.getIndexFromLine() - word.length;
			parser.parseWhitespaceOrComments();
			if(parser.parseWord("namespace")) {
				if(word == "start") {
					parser.parseWhitespaceOrComments();

					final nameStart = parser.getIndexFromLine();
					final names = parser.parseDotConnectedVarNames();
					if(names == null) {
						Error.addError(ErrorType.ExpectedNamespaceName, parser, nameStart);
						return null;
					}

					return NamespaceStart(names);
				} else if(word == "end") {
					if(!parser.scope.namespacesExist()) {
						Error.addError(ErrorType.NoNamespaceToEnd, parser, startOfModule);
						return null;
					}
					return NamespaceEnd;
				}
			}
		}

		parser.setIndex(index);

		return null;
	}
}
