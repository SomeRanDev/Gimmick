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
			var failed = false;

			parser.parseWhitespaceOrComments();

			final isGet = word == "get";
			final isSet = word == "set";

			final funcNameStart = parser.getIndexFromLine();
			var name = parser.parseNextVarName();
			if(name == null) {
				Error.addError(ErrorType.ExpectedVariableName, parser, funcNameStart);
				failed = true;
				name = "";
			}

			final funcNameEnd = parser.getIndexFromLine();
			final existingMembers = parser.scope.existInCurrentScopeAll(name);

			var existingMember = if(existingMembers != null && existingMembers.length == 1) {
				existingMembers[0];
			} else {
				null;
			}

			var anyIsGetSet = existingMember != null ? existingMember.isGetSet() : (isGet || isSet);
			if(existingMembers != null) {
				for(member in existingMembers) {
					if(member.isGetSet()) {
						anyIsGetSet = true;
						break;
					}
				}
			}

			if((isGet || isSet) != anyIsGetSet) {
				Error.addError(ErrorType.VariableNameAlreadyUsedInCurrentScope, parser, funcNameStart);
				failed = true;
			}

			var existingGetSet: Null<GetSetMember> = null;
			if(existingMember != null && existingMember.isGetSet() && (isGet || isSet)) {
				switch(existingMember.type) {
					case GetSet(getset): {
						existingGetSet = getset.get();
						if((isGet && !getset.get().isGetAvailable()) || (isSet && !getset.get().isSetAvailable())) {
							Error.addError(ErrorType.VariableNameAlreadyUsedInCurrentScope, parser, funcNameStart);
							failed = true;
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
						return Nothing;
					}
				}
			}

			if(isGet && arguments.length > 0) {
				Error.addError(ErrorType.GetRequiresNoArguments, parser, argListStart);
				failed = true;
			}

			if(isSet && arguments.length != 1) {
				Error.addError(ErrorType.SetRequiresOneArgument, parser, argListStart);
				failed = true;
			}

			if(existingMembers != null) {
				var exists = 0;
				for(member in existingMembers) {
					switch(member.type) {
						case Function(func): {
							if(!isGet && !isSet) {
								final existingArgs = func.get().type.get().arguments;
								var match = arguments.length == existingArgs.length;
								if(match) {
									for(i in 0...arguments.length) {
										if(i >= existingArgs.length) {
											match = false;
											break;
										}
										final arg = arguments[i];
										final existArg = existingArgs[i];
										if(!arg.type.equals(existArg.type)) {
											match = false;
											break;
										}
									}
								}
								if(match) {
									exists = 2;
									break;
								}
							}
						}
						case GetSet(getset): {}
						default: {
							exists = 1;
							break;
						}
					}
				}
				if(exists != 0) {
					final errorType = exists == 1 ? ErrorType.VariableNameAlreadyUsedInCurrentScope : ErrorType.FunctionNameWithParamsAlreadyUsedInScope;
					Error.addErrorWithStartEnd(errorType, parser, funcNameStart, funcNameEnd);
					failed = true;
				}
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
					failed = true;
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
				return Nothing;
			}

			if(failed) {
				return Nothing;
			}

			for(arg in arguments) {
				parser.onTypeUsed(arg.type, true);
			}
			parser.onTypeUsed(returnType, true);

			if(existingGetSet != null) {
				if(isGet) {
					existingGetSet.setGetter(funcMember);
					return Nothing;
				} else if(isSet) {
					existingGetSet.setSetter(funcMember);
					return Nothing;
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
