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
import parsers.error.Error;
import parsers.error.ErrorType;
import parsers.expr.Position;

class ParserModule_Attribute extends ParserModule {
	public static var it = new ParserModule_Attribute();

	public override function parse(parser: Parser): Null<Module> {
		final startState = parser.saveParserState();
		if(parser.parseNextContent("@")) {
			var failed = false;
			final varNameStart = parser.getIndex();
			final name = parser.parseNextVarName();
			if(name == null) {
				Error.addError(ErrorType.ExpectedAttributeName, parser, varNameStart);
				return Nothing;
			}

			final attr = parser.scope.findAttributeFromName(name);
			if(attr == null) {
				Error.addError(ErrorType.UnknownAttribute, parser, varNameStart);
				failed = true;
			}

			parser.parseWhitespaceOrComments();

			final paramsStartGlobal = parser.getIndex();
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

					var isRaw = false;
					var type: Null<AttributeArgumentType> = null;
					if(attr != null) {
						final withinAttr = attr.params != null && attr.params.length > index;
						type = infinityType != null ? infinityType : @:nullSafety(Off) (withinAttr ? attr.params[index].type : null);
						if(type != null ? type.isRaw() : false) {
							isRaw = true;
						} else if(!withinAttr && infinityType == null) {
							isRaw = true;
						}
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
						Error.addErrorAtChar(ErrorType.UnexpectedCharacter, parser);
						failed = true;
					}

					index++;
				}
			}

			if(failed || attr == null) {
				return Nothing;
			}

			return AttributeInstance(attr, params, parser.makePosition(paramsStartGlobal));

		} else if(parser.parseMultipleWords(["compiler", "attribute"]) != null) {
			final initialWord = parser.lastWordParsed;
			if(initialWord == "compiler") {
				parser.parseWhitespaceOrComments();
				if(!parser.parseWord("attribute")) {
					parser.restoreParserState(startState);
					return null;
				}
			}

			parser.parseWhitespaceOrComments();

			final varNameStart = parser.getIndex();
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
						final pos = parser.makePositionEx(line, startArgIndex, parser.getIndexFromLine());
						final attr = parseAttributeArugment(parser, pos);
						if(attr != null) {
							arguments.push(attr);
						} else {
							return null;
						}
						parser.parseWhitespaceOrComments();
						if(parser.parseNextContent(",")) {
						}
					}

					if(indexTracker == parser.getIndex() && argTracker == arguments.length) {
						Error.addErrorAtChar(ErrorType.UnexpectedCharacter, parser);
						return null;
					}
				}
			}

			final isCompilerAttribute = initialWord == "compiler";

			final attrMember = new AttributeMember(name, arguments, isCompilerAttribute, parser.makePosition(varNameStart));

			if(isCompilerAttribute) {
				if(parser.parseNextContent(":")) {
					parser.scope.push();
					final members = parser.parseNextLevelContent(CompilerAttribute);
					if(members != null) {
						attrMember.setAllMembers(members);
					}
					parser.scope.pop();
				} else if(parser.parseNextContent(";")) {
				} else {
					Error.addError(ErrorType.UnexpectedCharacterExpectedThisOrThat, parser, parser.getIndex(), 0, [":", ";"]);
					return null;
				}
			}

			return Attribute(attrMember);
		}

		return null;
	}

	public static function parseAttributeArugment(parser: Parser, position: Position): Null<AttributeArgument> {
		final argNameStart = parser.getIndex();
		final argName = parser.parseNextVarName();
		if(argName == null) {
			Error.addError(ErrorType.ExpectedFunctionParameterName, parser, argNameStart);
			return null;
		}
		parser.parseWhitespaceOrComments();

		var argStart = parser.getIndex();
		var typeArgStart = parser.getIndex();
		var argRealType = null;
		if(parser.parseNextContent(":")) {
			parser.parseWhitespaceOrComments();
			typeArgStart = parser.getIndex();
			argRealType = parser.parseType();
		} else {
			Error.addErrorAtChar(ErrorType.UnexpectedCharacter, parser);
			return null;
		}

		if(argRealType == null) {
			Error.addError(ErrorType.ExpectedType, parser, argStart);
			return null;
		}

		var argType = convertTypeToAttributeType(argRealType.type);
		if(argType == null) {
			Error.addError(ErrorType.InvalidTypeForAttribute, parser, typeArgStart);
			return null;
		}

		parser.parseWhitespaceOrComments();

		var expr = null;
		if(parser.parseNextContent("=")) {
			expr = parser.parseExpression();
		}

		return new AttributeArgument(argName, argType, argRealType.isOptional, position, expr);
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
			case List(l): {
				final internal = convertTypeToAttributeType(l.type, true);
				if(internal != null) {
					AttributeArgumentType.List(internal);
				} else {
					null;
				}
			}
			/*
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
			*/
			default: null;
		}
	}
}
