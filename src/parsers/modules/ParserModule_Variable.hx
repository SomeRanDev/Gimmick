package parsers.modules;

using haxe.EnumTools;

import ast.typing.Type;
import ast.scope.members.VariableMember;
import ast.scope.members.MemberLocation;

import parsers.Error;
import parsers.ErrorType;
import parsers.modules.ParserModule;

import parsers.expr.Position;
using parsers.expr.Expression;
using parsers.expr.TypedExpression;

class ParserModule_Variable extends ParserModule {
	public static var it = new ParserModule_Variable();

	public override function parse(parser: Parser): Null<Module> {
		final isPrelim = parser.isPreliminary();
		final startState = parser.saveParserState();
		final startIndex = parser.getIndex();

		final isExtern = parser.parseWord("extern");
		parser.parseWhitespaceOrComments();
		final word = parser.parseMultipleWords(["var", "const", "static"]);
		if(word != null) {
			var failed = false;

			parser.parseWhitespaceOrComments();

			final varNameStart = parser.getIndexFromLine();
			final name = parser.parseNextVarName();
			if(name == null) {
				Error.addError(ErrorType.ExpectedVariableName, parser, varNameStart);
				return null;
			}

			final existingMember = parser.scope.existInCurrentScope(name);
			if(existingMember != null) {
				Error.addError(ErrorType.VariableNameAlreadyUsedInCurrentScope, parser, varNameStart);
				failed = true;
			}

			parser.parseWhitespaceOrComments();

			var type = null;
			if(parser.parseNextContent(":")) {
				parser.parseWhitespaceOrComments();
				type = parser.parseType();
			}

			if(isExtern && type == null) {
				Error.addError(ErrorType.TypeRequiredOnExtern, parser, varNameStart);
				failed = true;
			}

			parser.parseWhitespaceOrComments();

			var expr = null;
			var equalsPos: Null<Position> = parser.makePosition(parser.getIndex());
			if(parser.parseNextContent("=")) {
				if(isExtern) {
					Error.addErrorFromPos(ErrorType.InvalidExpressionOnExtern, equalsPos);
					failed = true;
				}
				parser.parseWhitespaceOrComments();
				expr = parser.parseExpression();
			} else {
				equalsPos = null;
			}

			var typedExpr = null;
			var exprType: Null<Type> = null;
			if(expr != null) {
				typedExpr = expr.getType(parser, Preliminary);
				if(typedExpr != null) {
					exprType = typedExpr.getType();
					if(isPrelim && exprType == null) {
						exprType = Type.Unknown();
					}
				}
			}

			if(type == null) {
				type = exprType;
			}/* else if(!isPrelim && exprType != null) {
				final err = type.canBeAssigned(exprType);
				if(err != null) {
					final typeStr = type == null ? "" : type.toString();
					final exprStr = exprType == null ? "" : exprType.toString();
					Error.addErrorFromPos(err, equalsPos, [exprStr, typeStr]);
					return null;
				}
			}*/

			if(type != null && word == "const") {
				type.setConst();
			}

			/*if(type == null && expr == null) {
				Error.addError(ErrorType.CannotDetermineVariableType, parser, varNameStart);
				return null;
			}*/

			if(!parser.parseNextExpressionEnd()) {
				Error.addError(ErrorType.UnexpectedCharacter, parser, parser.getIndexFromLine());
				return Nothing;
			}

			if(failed) {
				return Nothing;
			}

			final finalType =  type == null ? Type.Unknown() : type;
			final isStatic = word == "static";
			final position = parser.makePosition(startIndex);
			final varMemberType = TopLevel(parser.scope.currentNamespaceStack());

			parser.onTypeUsed(finalType, parser.scope.isTopLevel());

			return Variable(new VariableMember(name, finalType, isStatic, isExtern, position, equalsPos, expr, varMemberType));
		}

		parser.restoreParserState(startState);

		return null;
	}
}
