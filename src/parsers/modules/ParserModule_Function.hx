package parsers.modules;

using haxe.EnumTools;

import basic.Ref;

import ast.scope.members.FunctionMember;
import ast.typing.Type;
import ast.typing.FunctionArgument;
import ast.typing.FunctionType;

import parsers.Error;
import parsers.ErrorType;
import parsers.modules.ParserModule;

import parsers.expr.Position;
using parsers.expr.Expression;
using parsers.expr.TypedExpression;

class ParserModule_Function extends ParserModule {
	public static var it = new ParserModule_Function();

	public override function parse(parser: Parser): Null<Module> {
		final isPrelim = parser.isPreliminary();
		final word = parser.parseMultipleWords(["get", "set", "def"]);
		final startIndex = parser.getIndex();
		if(word != null) {
			parser.parseWhitespaceOrComments();

			final funcNameStart = parser.getIndexFromLine();
			final name = parser.parseNextVarName();
			if(name == null) {
				Error.addError(ErrorType.ExpectedVariableName, parser, funcNameStart);
				return null;
			}

			if(parser.scope.existInCurrentScope(name)) {
				Error.addError(ErrorType.VariableNameAlreadyUsedInCurrentScope, parser, funcNameStart);
				return null;
			}

			parser.parseWhitespaceOrComments();

			final arguments: Array<FunctionArgument> = [];
			if(parser.parseNextContent("(")) {
				var indexTracker = 0;
				while(true) {
					parser.parseWhitespaceOrComments();

					indexTracker = parser.getIndex();

					if(parser.parseNextContent(")")) {
						break;
					} else {
						final argNameStart = parser.getIndexFromLine();
						final argName = parser.parseNextVarName();
						if(argName == null) {
							Error.addError(ErrorType.ExpectedFunctionParameterName, parser, argNameStart);
							return null;
						}
						parser.parseWhitespaceOrComments();
						if(parser.parseNextContent(",")) {
							arguments.push(new FunctionArgument(argName, Type.Unknown(), null));
						} else {
							var argType = null;
							parser.parseWhitespaceOrComments();
							if(parser.parseNextContent(":")) {
								argType = parser.parseType();
								parser.parseWhitespaceOrComments();
							}
							var createdArg = false;
							if(parser.parseNextContent("=")) {
								final expr = parser.parseExpression();
								if(expr != null) {
									final typedExpr = expr.getType(parser, parser.isPreliminary());
									if(argType == null && typedExpr != null) {
										argType = typedExpr.getType();
									}
									arguments.push(new FunctionArgument(argName, argType, typedExpr));
									createdArg = true;
								}
							}
							if(!createdArg) {
								arguments.push(new FunctionArgument(argName, argType == null ? Type.Unknown() : argType, null));
							}
							parser.parseWhitespaceOrComments();
							if(parser.parseNextContent(",")) {
							}
						}
					}

					if(indexTracker != parser.getIndex()) {
						Error.addError(ErrorType.UnexpectedCharacter, parser, parser.getIndexFromLine());
						return null;
					}
				}
			}

			parser.parseWhitespaceOrComments();

			var returnType: Null<Type> = null;
			if(parser.parseNextContent("->")) {
				parser.parseWhitespaceOrComments();
				returnType = parser.parseType();
			}

			if(returnType == null) {
				returnType = Type.Void();
			}

			//parser.parseWhitespaceOrComments();
			/*
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
				typedExpr = expr.getType(parser, isPrelim);
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
			*/

			parser.parseWhitespaceOrComments();

			final funcMember = new FunctionMember(name, new Ref(new FunctionType(arguments, returnType)));

			if(parser.parseNextContent(":")) {
				final currLine = parser.getLineNumber();
				parser.parseWhitespaceOrComments();
				if(currLine != parser.getLineNumber()) {
					parser.pushLevel(parser.getMode_Function());
				} else {
					parser.pushLevelOnSameLine(parser.getMode_Function());
				}
				parser.scope.push();
				final functionModules = parser.parseUntilLevelEnd();
				parser.popLevel();
				final members = parser.scope.pop();
				if(members != null) {
					funcMember.setAllMembers(members);
				}
			} else if(parser.parseNextContent(";")) {
			} else {
				Error.addError(ErrorType.UnexpectedCharacterExpectedThisOrThat, parser, parser.getIndexFromLine(), 0, [":", ";"]);
				return null;
			}

			for(arg in arguments) {
				parser.onTypeUsed(arg.type, true);
			}
			parser.onTypeUsed(returnType, true);

			return Function(funcMember);
		}

		return null;
	}
}
