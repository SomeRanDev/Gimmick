package parsers.modules;

using haxe.EnumTools;

import basic.Ref;
import basic.Tuple2;

using ast.scope.ScopeMember;
import ast.scope.members.FunctionMember;
import ast.scope.members.GetSetMember;
import ast.scope.members.MemberLocation;
using ast.scope.members.FunctionOption.FunctionOptionHelper;
import ast.typing.Type;
import ast.typing.FunctionArgument;
import ast.typing.FunctionType;

import parsers.error.Error;
import parsers.error.ErrorType;
import parsers.modules.ParserModule;

import parsers.expr.Position;
using parsers.expr.Expression;
using parsers.expr.TypedExpression;
import parsers.expr.Operator;
import parsers.expr.CallOperator;
import parsers.expr.InfixOperator;
import parsers.expr.PrefixOperator;
import parsers.expr.SuffixOperator;

class ParserModule_Function extends ParserModule {
	public static var it = new ParserModule_Function(0);
	public static var classIt = new ParserModule_Function(1);
	public static var modifyIt = new ParserModule_Function(2);

	var parser: Parser;

	var classFunctions = false;
	var modifyFunctions = false;

	var result: Null<Module> = null;
	var failed: Bool = false;
	var argListStart: Int = 0;
	var arguments: Array<FunctionArgument> = [];

	var isGet: Bool = false;
	var isSet: Bool = false;
	var isInit: Bool = false;
	var isDest: Bool = false;
	var isOp: Bool = false;

	public function new(type: Int) {
		super();
		parser = Parser.BLANK();
		classFunctions = type == 1;
		modifyFunctions = type == 2;
	}

	public function canParseOperators() {
		return classFunctions || modifyFunctions;
	}

	public override function parse(parser: Parser): Null<Module> {
		this.parser = parser;
		result = null;
		failed = false;

		final startState = parser.saveParserState();
		final startIndex = parser.getIndex();

		// Parse options (const, virtual, override, etc.)
		final options = FunctionOptionHelper.parseFunctionOptions(parser);

		// Parse first word
		final veryStart = parser.getIndexFromLine();
		final isPrelim = parser.isPreliminary();
		var word = parser.parseMultipleWords(["get", "set", "def", "init", "destroy", "prefix", "postfix", "infix", "op"]);
		var operatorType = 0;
		if(word == "prefix" || word == "postfix" || word == "infix" || word == "call") {
			operatorType = switch(word) {
				case "prefix": 1;
				case "postfix": 2;
				case "infix": 3;
				case "call": 4;
				default: 0;
			}
			parser.parseWhitespaceOrComments();
			word = parser.parseWord("op") ? "op" : null;
		}
		if(word != null && (classFunctions || (word != "init" && word != "destroy")) && (canParseOperators() || (word != "op"))) {
			parser.parseWhitespaceOrComments();

			// Determine function type
			isGet = word == "get";
			isSet = word == "set";
			isInit = word == "init";
			isDest = word == "destroy";
			isOp = word == "op";

			// Organize the options
			final attributes = [];
			for(opt in options) {
				var valid = false;
				final attr = opt.a;
				if(!classFunctions && attr.classOnly()) {
					Error.addErrorFromPos(ErrorType.InvalidFunctionAttributeForNonClassFunction, opt.b);
				} else if(isInit && !attr.constructorValid()) {
					Error.addErrorFromPos(ErrorType.InvalidFunctionAttributeForConstructor, opt.b);
				} else if(isDest && !attr.destructorValid()) {
					Error.addErrorFromPos(ErrorType.InvalidFunctionAttributeForDestructor, opt.b);
				} else if(isOp && !attr.operatorValid()) {
					Error.addErrorFromPos(ErrorType.InvalidFunctionAttributeForOperator, opt.b);
				} else {
					attributes.push(attr);
				}
			}

			// Parse function name if applicable
			var funcNameStart;
			var name;
			var opOverload = null;
			if(isInit || isDest) {
				funcNameStart = veryStart;
				name = "";
			} else if(isOp) {
				funcNameStart = veryStart;
				name = "";
				opOverload = findOperator(operatorType);
				if(opOverload != null) {
					parser.incrementIndex(opOverload.operatorLength());
				}
			} else {
				funcNameStart = parser.getIndex();
				var tempName = parser.parseNextVarName();
				if(tempName == null) {
					Error.addError(ErrorType.ExpectedVariableName, parser, funcNameStart);
					failed = true;
					tempName = "";
				}
				name = tempName;
			}

			// Check if existing member exists
			final funcNameEnd = parser.getIndexFromLine();
			final existingMembers = if(isOp && opOverload != null) {
				parser.scope.operatorExistInCurrentScopeAll(opOverload);
			} else {
				parser.scope.existInCurrentScopeAll(name);
			}

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

			final template = parser.parseGenericParameters();
			if(template != null) {
				parser.parseWhitespaceOrComments();
			}

			// Parse parameters
			if(parseParameters()) {
				return result;
			}

			checkForErrors(existingMembers, funcNameStart, funcNameEnd, opOverload);

			parser.parseWhitespaceOrComments();

			// Parse return type
			final returnType: Type = parseReturnType();

			parser.parseWhitespaceOrComments();

			// Generate actual name for getter/setter
			var functionName = name;
			if(isGet) {
				functionName = GetSetMember.generateGetFunctionName(name, parser.scope);
			} else if(isSet) {
				functionName = GetSetMember.generateSetFunctionName(name, parser.scope);
			}

			// Setup FunctionType
			final memberLocation = TopLevel(parser.scope.currentNamespaceStack());
			final funcType = new FunctionType(arguments, returnType);
			if(classFunctions) {
				if(isInit) {
					funcType.setConstructor();
				} else if(isDest) {
					funcType.setDestructor();
				} else if(isOp && opOverload != null) {
					funcType.setOperator(opOverload);
				} else {
					funcType.setClassFunction();
				}
			}

			if(template != null) {
				funcType.setTemplateArguments(template);
			}
			
			final funcMember = new FunctionMember(functionName, new Ref(funcType), memberLocation, attributes, parser.makePosition(startIndex));
			funcType.setMember(funcMember);

			if((!isGet && !isSet) && existingMembers != null && existingMembers.length > 0) {
				funcMember.setUniqueId(existingMembers.length + 1);
			}

			// Parse ending
			if(parser.parseNextContent(":")) {
				final members = parser.parseNextLevelContent();
				if(members != null) {
					funcMember.setAllMembers(members);
				}
			} else if(parser.parseNextContent(";")) {
			} else {
				Error.addError(ErrorType.UnexpectedCharacterExpectedThisOrThat, parser, parser.getIndex(), 0, [":", ";"]);
				return Nothing;
			}

			// Return Nothing if failed
			if(failed) {
				return Nothing;
			}

			// On types used
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

			if(opOverload != null) {
				return Operator(opOverload, funcMember);
			}
			return Function(funcMember);
		}

		parser.restoreParserState(startState);

		return null;
	}

	public function findOperator(operatorType: Int): Null<Operator> {
		final ops: Array<Operator> = switch(operatorType) {
			case 1: cast PrefixOperators.all();
			case 2: cast SuffixOperators.all();
			case 3: cast InfixOperators.all();
			case 4: cast CallOperators.all();
			default: cast InfixOperators.all().concat(cast SuffixOperators.all()).concat(cast PrefixOperators.all()).concat(cast CallOperators.all());
		}

		var maxLength = -1;
		final possibleOperators = [];
		for(op in ops) {
			if(op.checkIfNext(parser)) {
				possibleOperators.push(op);
				if(maxLength < op.operatorLength()) {
					maxLength = op.operatorLength();
				}
			}
		}

		var finalOperator: Null<Operator> = null;
		if(possibleOperators.length == 1) {
			finalOperator = possibleOperators[0];
		} else if(possibleOperators.length > 1) {
			for(op in possibleOperators) {
				if(op.operatorLength() == maxLength) {
					finalOperator = op;
					break;
				}
			}
		}
		
		return finalOperator;
	}

	public function parseParameters(): Bool {
		argListStart = parser.getIndex();
		arguments = [];
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
						result = null;
						return true;
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
					Error.addErrorAtChar(ErrorType.UnexpectedCharacter, parser);
					result = Nothing;
					return true;
				}
			}
		}
		return false;
	}

	public function checkForErrors(existingMembers: Null<Array<ScopeMember>>, funcNameStart: Int, funcNameEnd: Int, opOverload: Null<Operator>) {
		if(isDest && arguments.length > 0) {
			Error.addError(ErrorType.DestructorRequiresNoArguments, parser, argListStart);
			failed = true;
		}

		if(isGet && arguments.length > 0) {
			Error.addError(ErrorType.GetRequiresNoArguments, parser, argListStart);
			failed = true;
		}

		if(isSet && arguments.length != 1) {
			Error.addError(ErrorType.SetRequiresOneArgument, parser, argListStart);
			failed = true;
		}

		if(isOp && opOverload != null) {
			final desiredArgLength = opOverload.requiredArgumentLength();
			if(desiredArgLength != -1 && arguments.length != desiredArgLength) {
				Error.addError(ErrorType.WrongNumberOfArgumentsForOperator, parser, argListStart, [Std.string(desiredArgLength), Std.string(arguments.length)]);
			}
		}

		function check(func: Ref<FunctionMember>): Null<Int> {
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
			return match ? 2 : null;
		}

		if(existingMembers != null) {
			var exists = 0;
			for(member in existingMembers) {
				switch(member.type) {
					case Function(func) | PrefixOperator(_, func) | InfixOperator(_, func) | SuffixOperator(_, func) | CallOperator(_, func): {
						if(!isGet && !isSet) {
							final result = check(func);
							if(result != null) {
								exists = result;
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
				final errorType = if(exists == 1) {
					ErrorType.VariableNameAlreadyUsedInCurrentScope;
				} else if(isInit) {
					ErrorType.ConstructorWithParamsAlreadyInUse;
				} else if(isDest) {
					ErrorType.DestructorWithParamsAlreadyInUse;
				} else if(isOp) {
					OperatorWithParamsAlreadyInUse;
				} else {
					ErrorType.FunctionNameWithParamsAlreadyUsedInScope;
				};
				Error.addErrorWithStartEnd(errorType, parser, funcNameStart, funcNameEnd);
				failed = true;
			}
		}
	}

	public function parseReturnType(): Type {
		final returnStart = parser.getIndex();
		var returnType: Null<Type> = null;
		if(parser.parseNextContent("->")) {
			parser.parseWhitespaceOrComments();
			returnType = parser.parseType();
		}

		if(returnType == null) {
			if(isGet) {
				Error.addErrorAtChar(ErrorType.GetRequiresAReturn, parser);
				failed = true;
			}
			returnType = Type.Void();
		} else {
			if(isInit || isDest) {
				Error.addError(isInit ? ErrorType.ConstructorRequiresNoReturn : ErrorType.DestructorRequiresNoReturn, parser, returnStart);
				failed = true;
			}
		}
		return returnType;
	}
}
