package parsers.modules;

class ParserModule_Modify extends ParserModule {
	public static var it = new ParserModule_Modify();

	public override function parse(parser: Parser): Null<Module> {
		if(parser.parseWord("modify")) {

			parser.parseWhitespaceOrComments();

			// parse type
			final typeStart = parser.getIndexFromLine();
			final type = parser.parseType();
			if(type == null) {
				Error.addError(ErrorType.ExpectedType, parser, typeStart);
				return null;
			}

			if(parser.parseNextContent(":")) {
				parser.scope.push();
				final members = parser.parseNextLevelContent(Modify);
				if(members != null) {
					//attrMember.setAllMembers(members);
				}
				parser.scope.pop();
			} else if(parser.parseNextContent(";")) {
			} else {
				Error.addError(ErrorType.UnexpectedCharacterExpectedThisOrThat, parser, parser.getIndexFromLine(), 0, [":", ";"]);
				return null;
			}

			// return Attribute(attrMember);
		}
		return null;
	}
}
