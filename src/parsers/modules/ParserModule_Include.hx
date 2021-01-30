package parsers.modules;

import parsers.Parser;
import parsers.Error;
import parsers.ErrorType;
import parsers.modules.ParserModule;

class ParserModule_Include extends ParserModule {
	public static var it = new ParserModule_Include();

	public override function parse(parser: Parser): Null<Module> {
		final parseStart = parser.getIndex();

		final isHeader = parser.parseWord("header");
		parser.parseWhitespaceOrComments();
		final isSystem = parser.parseWord("system");
		parser.parseWhitespaceOrComments();

		if(parser.parseWord("include")) {
			parser.parseWhitespaceOrComments();

			final pathStart = parser.getIndexFromLine();
			final path = parser.parseContentUntilCharOrNewLine([";"]);

			return Include(path, isHeader, isSystem);
		} else {
			parser.setIndex(parseStart);
		}

		return null;
	}
}
