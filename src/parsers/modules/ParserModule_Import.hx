package parsers.modules;

import basic.Ref;

import ast.scope.Scope;

import parsers.Error;
import parsers.ErrorType;
import parsers.modules.ParserModule;

class ParserModule_Import extends ParserModule {
	public static var it = new ParserModule_Import();

	public override function parse(parser: Parser): Null<Module> {
		if(parser.parseWord("import")) {
			parser.parseWhitespaceOrComments();

			final pathStart = parser.getIndexFromLine();
			final path = parser.parseContentUntilCharOrNewLine(";");
			final hitSemicolon = parser.hitCharFlag;
			final file = parser.manager.beginParseFromPath(path);
			if(file == null) {
				Error.addError(ErrorType.UnknownImportPath, parser, pathStart);
			} else {
				// TODO: Add parsed file content to context.
				if(file.scope != null) {
					final myScope: Scope = file.scope;
					parser.scope.addImport(new Ref(myScope));
				}
			}

			if(hitSemicolon) {
				parser.parsePossibleCharacter(";");
			}

			return Import(path, null);
		}
		return null;
	}
}
