package parsers.modules;

using haxe.EnumTools;

import ast.typing.Type;
import ast.scope.members.VariableMember;
import ast.scope.members.MemberLocation;

import parsers.error.Error;
import parsers.error.ErrorType;
import parsers.modules.ParserModule;

import parsers.expr.Position;
using parsers.expr.Expression;
using parsers.expr.TypedExpression;

class ParserModule_Variable extends ParserModule {
	public static var it = new ParserModule_Variable(false);
	public static var externClassIt = new ParserModule_Variable(true);
	public static var modifyPrimitiveIt = new ParserModule_Variable(false, ErrorType.ModifyPrimitivesCannotContainVariables);

	var isForcedExtern = false;
	var failureType: Null<ErrorType> = null;

	public function new(isExtern: Bool, failureType: Null<ErrorType> = null) {
		super();
		isForcedExtern = isExtern;
		this.failureType = failureType;
	}

	public override function parse(parser: Parser): Null<Module> {
		final isPrelim = parser.isPreliminary();
		final startState = parser.saveParserState();
		final startIndex = parser.getIndex();

		final isExtern = parser.parseWord("extern") || isForcedExtern;
		parser.parseWhitespaceOrComments();
		final word = parser.parseMultipleWords(["var", "const", "static"]);
		if(word != null) {
			var failed = false;

			if(failureType != null) {
				failed = true;
			}

			parser.parseWhitespaceOrComments();

			final varNameStart = parser.getIndex();
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
			var varTypeStart = parser.getIndex();
			if(parser.parseNextContent(":")) {
				parser.parseWhitespaceOrComments();
				varTypeStart = parser.getIndex();
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
				Error.addErrorAtChar(ErrorType.UnexpectedCharacter, parser);
				return Nothing;
			}

			if(failureType != null) {
				Error.addError(failureType, parser, startIndex);
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
