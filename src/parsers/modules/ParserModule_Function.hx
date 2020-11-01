package parsers.modules;

using haxe.EnumTools;

import basic.Ref;

using ast.scope.ScopeMember;
import ast.scope.members.FunctionMember;
import ast.scope.members.GetSetMember;
import ast.scope.members.MemberLocation;
import ast.scope.members.FunctionOption.FunctionOptionHelper;
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
		final startIndex = parser.getIndex();

		final options = FunctionOptionHelper.parseFunctionOptions(parser);

		final isPrelim = parser.isPreliminary();
		final word = parser.parseMultipleWords(["get", "set", "def"]);
		if(word != null) {
			parser.parseWhitespaceOrComments();

			final isGet = word == "get";
			final isSet = word == "set";

			final funcNameStart = parser.getIndexFromLine();
			final name = parser.parseNextVarName();
			if(name == null) {
				Error.addError(ErrorType.ExpectedVariableName, parser, funcNameStart);
				return null;
			}

			final existingMember = parser.scope.existInCurrentScope(name);
			if(existingMember != null && (!existingMember.isGetSet() || (!isGet && !isSet))) {
				Error.addError(ErrorType.VariableNameAlreadyUsedInCurrentScope, parser, funcNameStart);
				return null;
			}

			var existingGetSet: Null<GetSetMember> = null;
			if(existingMember != null && existingMember.isGetSet() && (isGet || isSet)) {
				switch(existingMember.type) {
					case GetSet(getset): {
						existingGetSet = getset.get();
						if((isGet && !getset.get().isGetAvailable()) || (isSet && !getset.get().isSetAvailable())) {
							Error.addError(ErrorType.VariableNameAlreadyUsedInCurrentScope, parser, funcNameStart);
							return null;
						}
					}
					default: {}
				}
			}

			parser.parseWhitespaceOrComments();

			final argListStart = parser.getIndexFromLine();
			final arguments: Array<FunctionArgument> = [];
			if(parser.parseNextContent("(")) {
				var indexTracker = 0;
				var argTracker = 0;
				while(true) {
					parser.parseWhitespaceOrComments();

					indexTracker = parser.getIndex();
					argTracker = arguments.length;

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
									final typedExpr = expr.getType(parser, parser.isPreliminary() ? Preliminary : Normal);
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

					if(indexTracker != parser.getIndex() && argTracker == arguments.length) {
						Error.addError(ErrorType.UnexpectedCharacter, parser, parser.getIndexFromLine());
						return null;
					}
				}
			}

			if(isGet && arguments.length > 0) {
				Error.addError(ErrorType.GetRequiresNoArguments, parser, argListStart);
				return null;
			}

			if(isSet && arguments.length != 1) {
				Error.addError(ErrorType.SetRequiresOneArgument, parser, argListStart);
				return null;
			}

			parser.parseWhitespaceOrComments();

			var returnType: Null<Type> = null;
			if(parser.parseNextContent("->")) {
				parser.parseWhitespaceOrComments();
				returnType = parser.parseType();
			}

			if(returnType == null) {
				if(isGet) {
					Error.addError(ErrorType.GetRequiresAReturn, parser, parser.getIndexFromLine());
					return null;
				}
				returnType = Type.Void();
			}

			parser.parseWhitespaceOrComments();

			var functionName = name;

			if(isGet) {
				functionName = GetSetMember.generateGetFunctionName(name, parser.scope);
			} else if(isSet) {
				functionName = GetSetMember.generateSetFunctionName(name, parser.scope);
			}

			final memberLocation = TopLevel(parser.scope.currentNamespaceStack());
			final funcMember = new FunctionMember(functionName, new Ref(new FunctionType(arguments, returnType)), memberLocation, options);

			if(parser.parseNextContent(":")) {
				final members = parser.parseNextLevelContent();
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

			if(existingGetSet != null) {
				if(isGet) {
					existingGetSet.setGetter(funcMember);
					return null;
				} else if(isSet) {
					existingGetSet.setSetter(funcMember);
					return null;
				}
			} else {
				if(isGet) {
					return GetSet(new GetSetMember(name, funcMember, null));
				} else if(isSet) {
					return GetSet(new GetSetMember(name, null, funcMember));
				}
			}

			return Function(funcMember);
		}

		parser.setIndex(startIndex);

		return null;
	}
}
