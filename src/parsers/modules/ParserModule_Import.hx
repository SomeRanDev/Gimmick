package parsers.modules;

import parsers.Error;
import parsers.ErrorType;
import parsers.modules.ParserModule;

class ParserModule_Import extends ParserModule {
	public static var it = new ParserModule_Import();

	public override function parse(parser: Parser): Bool {
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
			}

			if(hitSemicolon) {
				parser.parsePossibleCharacter(";");
			}

			return true;
		}
		return false;
	}
}
