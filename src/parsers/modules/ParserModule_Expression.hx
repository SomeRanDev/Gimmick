package parsers.modules;

import parsers.Error;
import parsers.ErrorType;
import parsers.modules.ParserModule;
using parsers.expr.Expression;
import parsers.expr.ExpressionParser;

import ast.scope.ExpressionMember;

class ParserModule_Expression extends ParserModule {
	public static var it = new ParserModule_Expression();

	public override function parse(parser: Parser): Null<Module> {
		final result = parser.parseExpression();
		if(parser.isPreliminary()) {
			return null;
		}
		if(result != null) {
			final typed = result.getType(parser.scope, false);
			if(typed != null) {
				return Expression(Basic(typed));
			}
		}
		return null;
	}
}
