package parsers.modules;

import ast.scope.ScopeMember;
import ast.scope.members.AttributeMember;
import ast.scope.members.VariableMember;

using ast.typing.AttributeArgument;
import ast.typing.AttributeArgument.AttributeArgumentType;
import ast.typing.AttributeArgument.AttributeArgumentValue;

import ast.typing.FunctionArgument;
import ast.typing.Type.TypeType;

import parsers.ParserMode;
import parsers.expr.Position;

class ParserModule_Attribute extends ParserModule {
	public static var it = new ParserModule_Attribute();

	public override function parse(parser: Parser): Null<Module> {
		final startIndex = parser.getIndex();
		if(parser.parseNextContent("@")) {
			final varNameStart = parser.getIndexFromLine();
			final name = parser.parseNextVarName();
			if(name == null) {
				Error.addError(ErrorType.ExpectedAttributeName, parser, varNameStart);
				return null;
			}

			final attr = parser.scope.findAttributeFromName(name);
			if(attr == null) {
				Error.addError(ErrorType.UnknownAttribute, parser, varNameStart);
				return null;
			}

			parser.parseWhitespaceOrComments();

			final paramsStart = parser.getIndexFromLine();
			var params: Null<Array<AttributeArgumentValue>> = null;
			if(parser.parseNextContent("(")) {
				params = [];
				var index = 0;
				var infinityType: Null<AttributeArgumentType> = null;
				var indexTracker = 0;
				while(true) {
					parser.parseWhitespaceOrComments();
					indexTracker = parser.getIndex();

					final withinAttr = attr.params != null && attr.params.length > index;
					final type = infinityType != null ? infinityType : @:nullSafety(Off) (withinAttr ? attr.params[index].type : null);
					var isRaw = false;
					if(type != null ? type.isRaw() : false) {
						isRaw = true;
					} else if(!withinAttr && infinityType == null) {
						isRaw = true;
					}

					if(isRaw) {
						final raw = parser.parseContentUntilChar([",", ")"]);
						params.push(Raw(raw));
					} else if(type != null) {
						final expr = parser.parseExpression();
						if(expr == null) {
							return null;
						}
						params.push(Value(expr, type));
					}
					if(parser.parseNextContent(",")) {
					} else if(parser.parseNextContent(")")) {
						break;
					}

					if(indexTracker == parser.getIndex()) {
						Error.addError(ErrorType.UnexpectedCharacter, parser, parser.getIndexFromLine());
						return null;
					}
				}
			}

			return AttributeInstance(attr, params);

		} else if(parser.parseMultipleWords(["compiler", "attribute"]) != null) {
			final initialWord = parser.lastWordParsed;
			if(initialWord == "compiler") {
				parser.parseWhitespaceOrComments();
				if(!parser.parseWord("attribute")) {
					parser.setIndex(startIndex);
					return null;
				}
			}

			parser.parseWhitespaceOrComments();

			final varNameStart = parser.getIndexFromLine();
			final name = parser.parseNextVarName();
			if(name == null) {
				Error.addError(ErrorType.ExpectedAttributeName, parser, varNameStart);
				return null;
			}

			if(parser.scope.attributeExistInCurrentScope(name)) {
				Error.addError(ErrorType.AttributeNameAlreadyUsedInCurrentScope, parser, varNameStart);
				return null;
			}

			final arguments: Array<AttributeArgument> = [];
			final positions: Array<Position> = [];
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
						final line = parser.getLineNumber();
						final startArgIndex = parser.getIndexFromLine();
						final attr = parseAttributeArugment(parser);
						if(attr != null) {
							arguments.push(attr);
							positions.push(parser.makePositionEx(line, startArgIndex, parser.getIndexFromLine()));
						} else {
							return null;
						}
						parser.parseWhitespaceOrComments();
						if(parser.parseNextContent(",")) {
						}
					}

					if(indexTracker == parser.getIndex() && argTracker == arguments.length) {
						Error.addError(ErrorType.UnexpectedCharacter, parser, parser.getIndexFromLine());
						return null;
					}
				}
			}

			final isCompilerAttribute = initialWord == "compiler";

			if(isCompilerAttribute) {
				if(parser.parseNextContent(":")) {
					parser.scope.push();
					var index = 0;
					for(arg in arguments) {
						final v = new VariableMember(arg.name, arg.getType(), true, positions[index], null, ClassMember);
						parser.scope.addMemberToCurrentScope(new ScopeMember(Variable(v.getRef())));
						index++;
					}
					final members = parser.parseNextLevelContent(CompilerAttribute);
					if(members != null) {
						for(m in members) {
							switch(m.type) {
								case Function(func): {
									trace(func.get().name);
								}
								default: {}
							}
						}
						//funcMember.setAllMembers(members);
					}
					parser.scope.pop();
				} else if(parser.parseNextContent(";")) {
				} else {
					Error.addError(ErrorType.UnexpectedCharacterExpectedThisOrThat, parser, parser.getIndexFromLine(), 0, [":", ";"]);
					return null;
				}
			}

			return Attribute(new AttributeMember(name, arguments, isCompilerAttribute));
		}

		return null;
	}

	public static function parseAttributeArugment(parser: Parser): Null<AttributeArgument> {
		final argNameStart = parser.getIndexFromLine();
		final argName = parser.parseNextVarName();
		if(argName == null) {
			Error.addError(ErrorType.ExpectedFunctionParameterName, parser, argNameStart);
			return null;
		}
		parser.parseWhitespaceOrComments();

		var argStart = parser.getIndexFromLine();
		var argRealType = null;
		if(parser.parseNextContent(":")) {
			argRealType = parser.parseType();
		} else {
			Error.addError(ErrorType.UnexpectedCharacter, parser, parser.getIndexFromLine());
			return null;
		}

		if(argRealType == null) {
			Error.addError(ErrorType.ExpectedType, parser, argStart);
			return null;
		}

		var argType = convertTypeToAttributeType(argRealType.type);
		if(argType == null) {
			Error.addError(ErrorType.InvalidTypeForAttribute, parser, argStart);
			return null;
		}

		parser.parseWhitespaceOrComments();

		var expr = null;
		if(parser.parseNextContent("=")) {
			expr = parser.parseExpression();
		}

		return new AttributeArgument(argName, argType, argRealType.isOptional, expr);
	}

	public static function convertTypeToAttributeType(type: TypeType, recursive: Bool = false): Null<AttributeArgumentType> {
		return switch(type) {
			case Any: {
				AttributeArgumentType.Raw;
			}
			case Boolean: {
				AttributeArgumentType.Bool;
			}
			case Number(type): {
				switch(type) {
					case Any: AttributeArgumentType.Number;
					default: null;
				}
			}
			case String: {
				AttributeArgumentType.String;
			}
			case Class(cls, typeParams): {
				if(recursive) {
					null;
				} else {
					if(typeParams != null && typeParams.length == 1 && cls.get().name == "list") {
						final internal = convertTypeToAttributeType(typeParams[0].type, true);
						if(internal != null) {
							AttributeArgumentType.List(internal);
						} else {
							null;
						}
					} else {
						null;
					}
				}
			}
			default: null;
		}
	}
}
