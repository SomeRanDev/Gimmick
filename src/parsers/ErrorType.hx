package parsers;

enum abstract ErrorType(Int) from Int to Int {
	var UnknownImportPath = 1000;
	var UnexpectedEndOfString = 2000;
	var UnknownEscapeCharacter = 2100;
	var UnexpectedCharacterAfterExpression = 3000;
	var CouldNotConstructExpression = 3100;

	public function getErrorMessage(): String {
		switch(this) {
			case UnknownImportPath: return "Could not find source file based on path.";
			case UnexpectedEndOfString: return "Unexpected end of string.";
			case UnknownEscapeCharacter: return "Unknown escape character.";
			case UnexpectedCharacterAfterExpression: return "Unexpected character in expression.";
			case CouldNotConstructExpression: return "Could not construct expression";
		}
		return "";
	}

	public function getErrorLabel(): String {
		switch(this) {
			case UnknownImportPath: return "gimmick file not found";
			case UnexpectedEndOfString: return "unexpected end of string";
			case UnknownEscapeCharacter: return "unknown escape character";
			case UnexpectedCharacterAfterExpression: return "unexpected character";
			case CouldNotConstructExpression: return "could not build expression";
		}
		return "";
	}
}
