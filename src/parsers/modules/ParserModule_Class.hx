package parsers.modules;

import ast.typing.ClassType;
import ast.scope.members.ClassMember;
import ast.scope.members.MemberLocation;
import ast.scope.members.ClassOption.ClassOptionHelper;

import parsers.error.Error;
import parsers.error.ErrorType;

class ParserModule_Class extends ParserModule {
	public static var it = new ParserModule_Class();

	public override function parse(parser: Parser): Null<Module> {
		final startState = parser.saveParserState();

		final options = ClassOptionHelper.parseClassOptions(parser);

		if(parser.parseWord("class")) {
			var failed = false;

			parser.parseWhitespaceOrComments();

			final varNameStart = parser.getIndex();
			var name = parser.parseNextVarName();
			if(name == null) {
				Error.addError(ErrorType.ExpectedAttributeName, parser, varNameStart);
				failed = true;
				name = "";
			}

			if(parser.scope.findTypeFromName(name) != null) {
				Error.addError(ErrorType.ClassNameAlreadyUsedInCurrentScope, parser, varNameStart);
				failed = true;
			}

			final template = parser.parseGenericParameters();
			if(template != null) {
				parser.parseWhitespaceOrComments();
			}

			final clsType = new ClassType(name, null);

			if(template != null) {
				clsType.setTemplateArguments(template);
			}

			if(parser.parseNextContent(":")) {
				parser.scope.push();
				final members = parser.parseNextLevelContent(Class);
				if(members != null) {
					clsType.setAllMembers(members);
				}
				parser.scope.pop();
			} else if(parser.parseNextContent(";")) {
			} else {
				Error.addError(ErrorType.UnexpectedCharacterExpectedThisOrThat, parser, parser.getIndex(), 0, [":", ";"]);
				return null;
			}

			if(failed) {
				return Nothing;
			}

			final clsMemberType = TopLevel(parser.scope.currentNamespaceStack());
			final member = new ClassMember(name, clsType.getRef(), clsMemberType, options);
			clsType.setMember(member);
			return Class(member);
		}

		parser.restoreParserState(startState);

		return null;
	}
}
