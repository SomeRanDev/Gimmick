package parsers.modules;

import parsers.Error;
import parsers.ErrorType;
import parsers.modules.ParserModule;
import parsers.expr.ExpressionParser;

class ParserModule_Expression extends ParserModule {
	public static var it = new ParserModule_Expression();

	public override function parse(parser: Parser): Bool {
		final result = parser.parseExpression();
		return result != null;
	}
}
