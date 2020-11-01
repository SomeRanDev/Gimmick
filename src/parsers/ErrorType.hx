package parsers;

enum abstract ErrorType(Int) from Int to Int {
	var UnknownImportPath = 1000;

	var UnexpectedEndOfString = 2000;
	var UnknownEscapeCharacter = 2100;

	var UnexpectedCharacterAfterExpression = 3000;
	var CouldNotConstructExpression = 3100;

	var ExpectedVariableName = 4000;
	var ExpectedNamespaceName = 4001;
	var ExpectedAttributeName = 4002;
	var VariableNameAlreadyUsedInCurrentScope = 4010;
	var AttributeNameAlreadyUsedInCurrentScope = 4011;
	var NoNamespaceToEnd = 4020;

	var UnexpectedCharacter = 5000;
	var UnexpectedCharacterExpectedThis = 5001;
	var UnexpectedCharacterExpectedThisOrThat = 5002;
	var UnexpectedContent = 5100;

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

	var ExpectedCondition = 15000;

	var GetRequiresNoArguments = 16000;
	var GetRequiresAReturn = 16100;
	var SetRequiresOneArgument = 16200;

	var ExpectedType = 17000;
	var InvalidTypeForAttribute = 17010;
	var UnknownAttribute = 17020;
	var AttributeArgumentsMismatch = 17030;
	var MissingCompilerAttributeParameter = 17040;

	var InterpreterUnknownLiteral = 20000;
	var InterpreterLiteralListValuesDoNotMatch = 20010;
	var InterpreterInvalidLExpr = 20020;
	var InterpreterCannotAssignDifferentTypes = 20030;
	var InterpreterMustReturnBool = 20100;
	var InterpreterCannotCallType = 20200;
	var InterpreterArrayAccessExpectsOneNumber = 20300;
	var InterpreterAccessOutsideStringSize = 20310;
	var InterpreterAccessOutsideArraySize = 20311;
	var InterpreterInvalidAccessor = 20400;

	var InvalidThisOrSelf = 30000;

	public function getErrorMessage(): String {
		switch(this) {
			case UnknownImportPath: return "Could not find source file based on path.";
			case UnexpectedEndOfString: return "Unexpected end of string.";
			case UnknownEscapeCharacter: return "Unknown escape character.";
			case UnexpectedCharacterAfterExpression: return "Unexpected character in expression.";
			case CouldNotConstructExpression: return "Could not construct expression.";

			case ExpectedVariableName: return "Variable name expected.";
			case ExpectedNamespaceName: return "Namespace name or path expected.";
			case ExpectedAttributeName: return "Attribute name expected.";
			case VariableNameAlreadyUsedInCurrentScope: return "Name already in use.";
			case AttributeNameAlreadyUsedInCurrentScope: return "Attribute name already in use.";
			case NoNamespaceToEnd: return "No namespace to end.";

			case UnexpectedCharacter: return "Unexpected character encountered.";
			case UnexpectedCharacterExpectedThis: return "Unexpected character. Expected '%1'.";
			case UnexpectedCharacterExpectedThisOrThat: return "Unexpected character. Expected '%1' or '%2'.";
			case UnexpectedContent: return "Unexpected content encountered in scope.";

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

			case ExpectedCondition: return "Expected condition expression.";

			case GetRequiresNoArguments: return "Get function cannot accept arguments.";
			case GetRequiresAReturn: return "Get function requires a return type.";
			case SetRequiresOneArgument: return "Set function requires exactly one argument.";
		
			case ExpectedType: return "Expected type.";
			case InvalidTypeForAttribute: return "Invalid type for attribute.";
			case UnknownAttribute: return "Unknown attribute.";
			case AttributeArgumentsMismatch: return "Invalid arguments for attribute.";
			case MissingCompilerAttributeParameter: return "Missing compiler attribute parameter #%1: '%2'.";

			case InterpreterUnknownLiteral: return "Unknown value encountered.";
			case InterpreterLiteralListValuesDoNotMatch: return "List types do not match. Expected '%1'. not '%2'.";
			case InterpreterInvalidLExpr: return "Invalid left-expression for assignment.";
			case InterpreterCannotAssignDifferentTypes: return "Cannot assign '%1' to '%2' variable.";
			case InterpreterMustReturnBool: return "Expression should return bool, not '%1'.";
			case InterpreterCannotCallType: return "Cannot call type '%1'.";
			case InterpreterArrayAccessExpectsOneNumber: return "Single number value expected for array access.";

			case InterpreterAccessOutsideStringSize: return "Access made outside string size (index: %1, size: %2).";
			case InterpreterAccessOutsideArraySize: return "Access made outside array size (index: %1, size: %2).";

			case InterpreterInvalidAccessor: return "Invalid accessor value.";

			case InvalidThisOrSelf: return "Invalid usage of 'this'.";
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
			case ExpectedAttributeName: return "expected attribute name";
			case VariableNameAlreadyUsedInCurrentScope: return "name already in use";
			case AttributeNameAlreadyUsedInCurrentScope: return "attribute name already in use";
			case NoNamespaceToEnd: return "no namespaces to end";

			case UnexpectedCharacter: return "unexpected character";
			case UnexpectedCharacterExpectedThis: return "unexpected character";
			case UnexpectedCharacterExpectedThisOrThat: return "unexpected character";
			case UnexpectedContent: return "unexpected content";

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

			case ExpectedCondition: return "expected condition";

			case GetRequiresNoArguments: return "cannot accept arguments";
			case GetRequiresAReturn: return "return type required";
			case SetRequiresOneArgument: return "exactly one argument required";

			case ExpectedType: return "expected type here";
			case InvalidTypeForAttribute: return "invalid type for attribute";
			case UnknownAttribute: return "unknown attribute";
			case AttributeArgumentsMismatch: return "invalid arguments";
			case MissingCompilerAttributeParameter: return "missing compiler attribute parameter";

			case InterpreterUnknownLiteral: return "unknown value";
			case InterpreterLiteralListValuesDoNotMatch: return "list value types do not match";
			case InterpreterInvalidLExpr: "invalid lexpr";
			case InterpreterCannotAssignDifferentTypes: return "cannot assign mismatched types";
			case InterpreterMustReturnBool: return "expression doesn't return bool";
			case InterpreterCannotCallType: return "cannot call variable";
			case InterpreterArrayAccessExpectsOneNumber: return "single number expected";

			case InterpreterAccessOutsideStringSize: return "accessed outside string size";
			case InterpreterAccessOutsideArraySize: return "accessed outside array size";

			case InterpreterInvalidAccessor: return "invalid accessor value";

			case InvalidThisOrSelf: return "invalid 'this'";
		}
		return "";
	}
}
