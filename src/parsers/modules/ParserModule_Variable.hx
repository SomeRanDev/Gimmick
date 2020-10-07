package parsers.modules;

using haxe.EnumTools;

import ast.scope.members.VariableMember;
import ast.typing.Type;

import parsers.Error;
import parsers.ErrorType;
import parsers.modules.ParserModule;
using parsers.expr.Expression;
using parsers.expr.TypedExpression;

class ParserModule_Variable extends ParserModule {
	public static var it = new ParserModule_Variable();

	public override function parse(parser: Parser): Null<Module> {
		final isPrelim = parser.isPreliminary();
		final word = parser.parseMultipleWords(["var", "const", "static"]);
		if(word != null) {
			parser.parseWhitespaceOrComments();

			final varNameStart = parser.getIndexFromLine();
			final name = parser.parseNextVarName();
			if(name == null) {
				Error.addError(ErrorType.ExpectedVariableName, parser, varNameStart);
				return null;
			}

			if(parser.scope.existInCurrentScope(name)) {
				Error.addError(ErrorType.VariableNameAlreadyUsedInCurrentScope, parser, varNameStart);
				return null;
			}

			parser.parseWhitespaceOrComments();

			var type = null;
			if(parser.parseNextContent(":")) {
				parser.parseWhitespaceOrComments();
				type = parser.parseType();
			}

			parser.parseWhitespaceOrComments();

			var expr = null;
			var equalsPos = parser.makePosition(parser.getIndex());
			if(parser.parseNextContent("=")) {
				parser.parseWhitespaceOrComments();
				expr = parser.parseExpression();
			}

			var typedExpr = null;
			var exprType: Null<Type> = null;
			if(expr != null) {
				typedExpr = expr.getType(parser.scope, isPrelim);
				if(typedExpr != null) {
					exprType = typedExpr.getType();
					if(isPrelim && exprType == null) {
						exprType = Type.Unknown();
					}
				}
			}

			if(type == null) {
				type = exprType;
			} else if(!isPrelim && exprType != null) {
				final err = type.canBeAssigned(exprType);
				if(err != null) {
					final typeStr = type == null ? "" : type.toString();
					final exprStr = exprType == null ? "" : exprType.toString();
					Error.addErrorFromPos(err, equalsPos, [exprStr, typeStr]);
					return null;
				}
			}

			if(type != null && word == "const") {
				type.setConst();
			}

			if(type == null && expr == null) {
				Error.addError(ErrorType.CannotDetermineVariableType, parser, varNameStart);
				return null;
			}

			return Variable(new VariableMember(name, type == null ? Type.Unknown() : type, word == "static", typedExpr));
		}

		return null;
	}
}
