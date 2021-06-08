package parsers.modules;

import ast.scope.ScopeMember;
import ast.scope.members.ClassMember;
import ast.scope.members.MemberLocation;
import ast.scope.members.ClassOption.ClassOptionHelper;

import ast.typing.Type;
import ast.typing.ClassType;

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
			// TODO: FIx the fact there is error cause it gets parsed multiple times??
			if(name == "QObject") trace(haxe.CallStack.toString(haxe.CallStack.callStack()));

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
				parser.scope.push();
				clsType.setTemplateArguments(template);
				for(i in 0...template.length) {
					parser.scope.addMember(new ScopeMember(TemplateType(i, template[i].getRef())));
				}
			}

			if(parser.parseWord("extends")) {
				parser.parseWhitespaceOrComments();
				final extendTypes: Array<Type> = [];
				while(true) {
					final t = parser.parseType();
					if(t != null) {
						extendTypes.push(t);
						parser.parseWhitespaceOrComments();
						if(parser.checkAheadWord(",")) {
							parser.parseWhitespaceOrComments();
						} else {
							break;
						}
					} else {
						break;
					}
				}
				clsType.setExtendedTypes(extendTypes);
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
				failed = true;
			}

			if(template != null) {
				parser.scope.pop();
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
