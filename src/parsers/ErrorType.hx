package parsers;

enum abstract ErrorType(Int) from Int to Int {
	var UnknownImportPath = 1000;

	var UnexpectedEndOfString = 2000;
	var UnknownEscapeCharacter = 2100;

	var UnexpectedCharacterAfterExpression = 3000;
	var CouldNotConstructExpression = 3100;

	var ExpectedVariableName = 4000;
	var ExpectedNamespaceName = 4001;
	var VariableNameAlreadyUsedInCurrentScope = 4010;
	var NoNamespaceToEnd = 4020;

	var UnexpectedCharacter = 5000;
	var UnexpectedCharacterExpectedThis = 5001;
	var UnexpectedCharacterExpectedThisOrThat = 5002;
	var InvalidTypeParameter = 6000;
	var ExpectedExternalName = 7000;
	var UnknownType = 8000;
	var InvalidNumericCharacters = 9000;

	var InvalidPrefixOperator = 10000;
	var InvalidSuffixOperator = 10010;
	var InvalidCallOperator = 10015;
	var InvalidInfixOperator = 10020;
	var InvalidValue = 10030;
	var UnknownVariable = 10040;
	var UnknownMember = 10050;

	var CannotDetermineVariableType = 11000;
	var CannotAssignThisTypeToThatType = 12000;
	var CannotAssignToConst = 12010;

	var ExpectedFunctionParameterName = 13000;

	var InconsistentIndent = 14000;

	public function getErrorMessage(): String {
		switch(this) {
			case UnknownImportPath: return "Could not find source file based on path.";
			case UnexpectedEndOfString: return "Unexpected end of string.";
			case UnknownEscapeCharacter: return "Unknown escape character.";
			case UnexpectedCharacterAfterExpression: return "Unexpected character in expression.";
			case CouldNotConstructExpression: return "Could not construct expression.";

			case ExpectedVariableName: return "Variable name expected.";
			case ExpectedNamespaceName: return "Namespace name or path expected.";
			case VariableNameAlreadyUsedInCurrentScope: return "Name already in use.";
			case NoNamespaceToEnd: return "No namespace to end.";

			case UnexpectedCharacter: return "Unexpected character encountered.";
			case UnexpectedCharacterExpectedThis: return "Unexpected character. Expected '%1'.";
			case UnexpectedCharacterExpectedThisOrThat: return "Unexpected character. Expected '%1' or '%2'.";
			case InvalidTypeParameter: return "Invalid type parameter setup.";
			case ExpectedExternalName: return "Expected name for external type.";
			case UnknownType: return "Unknown type found.";
			case InvalidNumericCharacters: return "Invalid literal numeric descriptors.";

			case InvalidPrefixOperator: return "Invalid prefix usage for '%1'.";
			case InvalidSuffixOperator: return "Invalid suffix usage for '%1'.";
			case InvalidCallOperator: return "Invalid call usage for '%1'.";
			case InvalidInfixOperator: return "Invalid infix usage for '%1' and '%2'.";
			case InvalidValue: return "Invalid value.";
			case UnknownVariable: return "Unknown variable '%1'.";
			case UnknownMember: return "Unknown member '%1' of '%2'";

			case CannotDetermineVariableType: return "Cannot determine variable type.";
			case CannotAssignThisTypeToThatType: return "Cannot assign '%1' to '%2'.";
			case CannotAssignToConst: return "Cannot assign to const variable.";

			case ExpectedFunctionParameterName: return "Expected function parameter name.";

			case InconsistentIndent: return "Inconsistent indent.";
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

			case ExpectedVariableName: return "expected variable name";
			case ExpectedNamespaceName: return "expected namespace name";
			case VariableNameAlreadyUsedInCurrentScope: return "name already in use";
			case NoNamespaceToEnd: return "no namespaces to end";

			case UnexpectedCharacter: return "unexpected character";
			case UnexpectedCharacterExpectedThis: return "unexpected character";
			case UnexpectedCharacterExpectedThisOrThat: return "unexpected character";
			case InvalidTypeParameter: return "type parameters cannot be used on primitives";
			case ExpectedExternalName: return "external name expected";
			case UnknownType: return "type name expected here";
			case InvalidNumericCharacters: return "unexcepted characters";

			case InvalidPrefixOperator: return "invalid prefix operator";
			case InvalidSuffixOperator: return "invalid suffix operator";
			case InvalidCallOperator: return "invalid call operator";
			case InvalidInfixOperator: return "invalid infix operator";
			case InvalidValue: return "invalid value";
			case UnknownVariable: return "unknown variable";
			case UnknownMember: return "unknown member";

			case CannotDetermineVariableType: return "cannot determine type";
			case CannotAssignThisTypeToThatType: return "cannot assign different types";
			case CannotAssignToConst: return "cannot assign to const";

			case ExpectedFunctionParameterName: return "expected name here";

			case InconsistentIndent: return "inconsistent indent";
		}
		return "";
	}
}
