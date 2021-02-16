package parsers.modules;

import ast.typing.Type;

import ast.scope.members.ModifyMember;

import parsers.error.Error;
import parsers.error.ErrorType;

class ParserModule_Modify extends ParserModule {
	public static var it = new ParserModule_Modify();

	public override function parse(parser: Parser): Null<Module> {
		final start = parser.getIndex();
		if(parser.parseWord("modify")) {

			parser.parseWhitespaceOrComments();

			// parse type
			final typeStart = parser.getIndex();
			final type = parser.parseType();
			if(type == null) {
				Error.addError(ErrorType.ExpectedType, parser, typeStart);
				return Nothing;
			}

			final modify = new ModifyMember(type, parser.makePosition(start));
			if(parser.parseNextContent(":")) {
				parser.scope.push();
				final members = parser.parseNextLevelContent(Modify);
				if(members != null) {
					modify.setAllMembers(members, parser.scope);
				}
				parser.scope.pop();
			} else if(parser.parseNextContent(";")) {
			} else {
				Error.addError(ErrorType.UnexpectedCharacterExpectedThisOrThat, parser, parser.getIndex(), 0, [":", ";"]);
				return Nothing;
			}

			return Modify(modify);
		}
		return null;
	}
}
