package parsers.error;

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
	var FunctionNameWithParamsAlreadyUsedInScope = 4011;
	var AttributeNameAlreadyUsedInCurrentScope = 4012;
	var ClassNameAlreadyUsedInCurrentScope = 4013;
	var ConstructorWithParamsAlreadyInUse = 4014;
	var DestructorWithParamsAlreadyInUse = 4015;
	var OperatorWithParamsAlreadyInUse = 4016;
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
	var AmbiguousFunctionCall = 10060;
	var AmbiguousFunctionCall3 = 10061;
	var AmbiguousFunctionCallMulti = 10062;

	var CannotDetermineVariableType = 11000;
	var CannotAssignThisTypeToThatType = 12000;
	var CannotAssignToConst = 12010;
	var CannotAssignNullToNonOptional = 12020;

	var ExpectedFunctionParameterName = 13000;

	var InconsistentIndent = 14000;

	var ExpectedCondition = 15000;

	var InvalidFunctionAttributeForNonClassFunction = 16000;

	var GetRequiresNoArguments = 16100;
	var GetRequiresAReturn = 16200;
	var SetRequiresOneArgument = 16300;

	var ConstructorRequiresNoReturn = 16500;
	var DestructorRequiresNoReturn = 16600;
	var DestructorRequiresNoArguments = 16700;
	var InvalidFunctionAttributeForConstructor = 16800;
	var InvalidFunctionAttributeForDestructor = 16900;

	var WrongNumberOfArgumentsForOperator = 17000;
	var InvalidFunctionAttributeForOperator = 17100;

	var ExpectedType = 18000;
	var InvalidTypeForAttribute = 18010;
	var UnknownAttribute = 18020;
	var AttributeArgumentsMismatch = 18030;
	var MissingCompilerAttributeParameter = 18040;
	var TypeRequiredOnExtern = 18050;
	var InvalidExpressionOnExtern = 18060;
	var InvalidFunctionContentOnExtern = 18070;

	var MissingFunctionParameter = 19000;
	var CannotPassThisForThat = 19100;
	var TooManyFunctionParametersProvided = 19200;
	var ClassHasNoConstructors = 19300;

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

	var MustUseClassTypeOnExtendsGenericDescriber = 31000;
	var TooManyTemplateParameters = 31100;
	var TypeDoesNotHaveTemplate = 31200;
	var TypeDoesNotMeetRequirement = 31300;
	var NotEnoughTemplateParameters = 31400;
	var FunctionRequiresTypeArguments = 31500;
	var ClassRequiresTypeArguments = 31600;

	var CannotDetermineParameterType = 32000;

	var ReturnedTypeDoesNotMatchReturnType = 32100;
	var ReturnExpressionExpected = 32200;
	var NoReturnExpressionExpected = 32300;
	var NoReturnOnFunction = 32400;

	var TypeCannotBeExtended = 33000;
	var InvalidVariableType = 33100;
	var InvalidFunctionParameterType = 33200;
	var InvalidFunctionReturnType = 33300;

	var ModifyPrimitivesCannotContainVariables = 34000;

	var JsCannotUseDestructor = 40000;
	var JsCannotHaveMultipleConstructors = 40100;

	public function getErrorMessage(): String {
		return switch(this) {
			case UnknownImportPath: "Could not find source file based on path.";
			case UnexpectedEndOfString: "Unexpected end of string.";
			case UnknownEscapeCharacter: "Unknown escape character.";
			case UnexpectedCharacterAfterExpression: "Unexpected character in expression.";
			case CouldNotConstructExpression: "Could not construct expression.";

			case ExpectedVariableName: "Variable name expected.";
			case ExpectedNamespaceName: "Namespace name or path expected.";
			case ExpectedAttributeName: "Attribute name expected.";
			case VariableNameAlreadyUsedInCurrentScope: "Name already in use.";
			case FunctionNameWithParamsAlreadyUsedInScope: "Function with this name and parameters already exists.";
			case AttributeNameAlreadyUsedInCurrentScope: "Attribute name already in use.";
			case ClassNameAlreadyUsedInCurrentScope: "Class name already in use.";
			case ConstructorWithParamsAlreadyInUse: "Constructor with these parameters already exists.";
			case DestructorWithParamsAlreadyInUse: "Destructor with these parameters already exists.";
			case OperatorWithParamsAlreadyInUse: "This operator with these parameters already exists.";
			case NoNamespaceToEnd: "No namespace to end.";

			case UnexpectedCharacter: "Unexpected character encountered.";
			case UnexpectedCharacterExpectedThis: "Unexpected character. Expected '%1'.";
			case UnexpectedCharacterExpectedThisOrThat: "Unexpected character. Expected '%1' or '%2'.";
			case UnexpectedContent: "Unexpected content encountered in scope.";

			case InvalidTypeParameter: "Invalid type parameter setup.";
			case ExpectedExternalName: "Expected name for external type.";
			case UnknownType: "Unknown type found.";
			case InvalidNumericCharacters: "Invalid literal numeric descriptors.";

			case InvalidPrefixOperator: "Invalid prefix usage for '%1'.";
			case InvalidSuffixOperator: "Invalid suffix usage for '%1'.";
			case InvalidCallOperator: "Invalid call usage for '%1'.";
			case InvalidInfixOperator: "Invalid infix usage for '%1' and '%2'.";
			case InvalidValue: "Invalid value.";
			case UnknownVariable: "Unknown variable '%1'.";
			case UnknownMember: "Unknown member '%1' of '%2'.";
			case AmbiguousFunctionCall: "Ambiguous function call. Could be '%1' or '%2'.";
			case AmbiguousFunctionCall3: "Ambiguous function call. Could be '%1', '%2', or '%3'.";
			case AmbiguousFunctionCallMulti: "Ambiguous function call. Could be '%1', '%2', or %3 others.";

			case CannotDetermineVariableType: "Cannot determine variable type.";
			case CannotAssignThisTypeToThatType: "Cannot assign '%1' to '%2'.";
			case CannotAssignToConst: "Cannot assign to const variable.";
			case CannotAssignNullToNonOptional: "Cannot assign null to non-nullable value.";

			case ExpectedFunctionParameterName: "Expected function parameter name.";

			case InconsistentIndent: "Inconsistent indent.";

			case ExpectedCondition: "Expected condition expression.";

			case InvalidFunctionAttributeForNonClassFunction: "Invalid function attribute for function without a class.";

			case GetRequiresNoArguments: "Get function cannot accept arguments.";
			case GetRequiresAReturn: "Get function requires a type.";
			case SetRequiresOneArgument: "Set function requires exactly one argument.";

			case ConstructorRequiresNoReturn: "Constructors should not have a value.";
			case DestructorRequiresNoReturn: "Destructors should not have a value.";
			case DestructorRequiresNoArguments: "Destructors should not have arguments.";
			case InvalidFunctionAttributeForConstructor: "Invalid function attribute for constructor.";
			case InvalidFunctionAttributeForDestructor: "Invalid function attribute for destructor.";

			case WrongNumberOfArgumentsForOperator: "Wrong number of arguments for this operator. Should be %1, but there are %2.";
			case InvalidFunctionAttributeForOperator: "Invalid function attribute for operator.";

			case ExpectedType: "Expected type.";
			case InvalidTypeForAttribute: "Invalid type for attribute.";
			case UnknownAttribute: "Unknown attribute.";
			case AttributeArgumentsMismatch: "Invalid arguments for attribute.";
			case MissingCompilerAttributeParameter: "Missing compiler attribute parameter #%1: '%2'.";
			case TypeRequiredOnExtern: "Type required for extern variable.";
			case InvalidExpressionOnExtern: "Expression invalid on extern variable.";
			case InvalidFunctionContentOnExtern: "Function content invalid on extern function.";

			case MissingFunctionParameter: "Missing function parameter.";
			case CannotPassThisForThat: "Cannot pass '%1' for '%2'.";
			case TooManyFunctionParametersProvided: "Too many function parameters provided.";
			case ClassHasNoConstructors: "'%1' does not have a constructor.";

			case InterpreterUnknownLiteral: "Unknown value encountered.";
			case InterpreterLiteralListValuesDoNotMatch: "List types do not match. Expected '%1'. not '%2'.";
			case InterpreterInvalidLExpr: "Invalid left-expression for assignment.";
			case InterpreterCannotAssignDifferentTypes: "Cannot assign '%1' to '%2' variable.";
			case InterpreterMustReturnBool: "Expression should bool, not '%1'.";
			case InterpreterCannotCallType: "Cannot call type '%1'.";
			case InterpreterArrayAccessExpectsOneNumber: "Single number value expected for array access.";

			case InterpreterAccessOutsideStringSize: "Access made outside string size (index: %1, size: %2).";
			case InterpreterAccessOutsideArraySize: "Access made outside array size (index: %1, size: %2).";

			case InterpreterInvalidAccessor: "Invalid accessor value.";

			case InvalidThisOrSelf: "Invalid usage of 'this'.";

			case MustUseClassTypeOnExtendsGenericDescriber: "Must use a class type for 'extends' template descriptor.";
			case TooManyTemplateParameters: "Too many template parameters provided. Should be at most %1, but there are %2.";
			case TypeDoesNotHaveTemplate: "Type parameters provided to class or function without template.";
			case TypeDoesNotMeetRequirement: "Provided type parameter '%1' does not meet requirement: '%2'.";
			case NotEnoughTemplateParameters: "Not enough template parameters provided. Should be at least %1, but there are only %2.";
			case FunctionRequiresTypeArguments: "Function requires type arguments for template.";
			case ClassRequiresTypeArguments: "Class requires type arguments for template.";

			case CannotDetermineParameterType: "Cannot determine the type of the function parameter '%1'.";

			case ReturnedTypeDoesNotMatchReturnType: "The returned expression type, '%1', does not match the desired return type, '%2'.";
			case ReturnExpressionExpected: "Expression returning value of type '%1' expected.";
			case NoReturnExpressionExpected: "Lack of expression expected for this return.";
			case NoReturnOnFunction: "End of function can be reached without guaranteed return.";

			case TypeCannotBeExtended: "The type '%1' cannot be extended from.";
			case InvalidVariableType: "'%1' is not a valid variable type.";
			case InvalidFunctionParameterType: "'%1' is not a valid function parameter type.";
			case InvalidFunctionReturnType: "'%1' is not a valid function return type.";
			
			case ModifyPrimitivesCannotContainVariables: "Modify cannot modify fields of primitives.";

			case JsCannotUseDestructor: "JS export cannot use destructors.";
			case JsCannotHaveMultipleConstructors: "JS export cannot use multiple constructors.";

			default: "";
		}
	}

	public function getErrorLabel(): String {
		return switch(this) {
			case UnknownImportPath: "gimmick file not found";
			case UnexpectedEndOfString: "unexpected end of string";
			case UnknownEscapeCharacter: "unknown escape character";
			case UnexpectedCharacterAfterExpression: "unexpected character";
			case CouldNotConstructExpression: "could not build expression";

			case ExpectedVariableName: "expected variable name";
			case ExpectedNamespaceName: "expected namespace name";
			case ExpectedAttributeName: "expected attribute name";
			case VariableNameAlreadyUsedInCurrentScope: "name already in use";
			case FunctionNameWithParamsAlreadyUsedInScope: "name already in use";
			case AttributeNameAlreadyUsedInCurrentScope: "attribute name already in use";
			case ClassNameAlreadyUsedInCurrentScope: "class name already in use";
			case ConstructorWithParamsAlreadyInUse: "constructor already exists";
			case DestructorWithParamsAlreadyInUse: "destructor already exists";
			case OperatorWithParamsAlreadyInUse: "operator already exists";
			case NoNamespaceToEnd: "no namespaces to end";

			case UnexpectedCharacter: "unexpected character";
			case UnexpectedCharacterExpectedThis: "unexpected character";
			case UnexpectedCharacterExpectedThisOrThat: "unexpected character";
			case UnexpectedContent: "unexpected content";

			case InvalidTypeParameter: "type parameters cannot be used on primitives";
			case ExpectedExternalName: "external name expected";
			case UnknownType: "type name expected here";
			case InvalidNumericCharacters: "unexcepted characters";

			case InvalidPrefixOperator: "invalid prefix operator";
			case InvalidSuffixOperator: "invalid suffix operator";
			case InvalidCallOperator: "invalid call operator";
			case InvalidInfixOperator: "invalid infix operator";
			case InvalidValue: "invalid value";
			case UnknownVariable: "unknown variable";
			case UnknownMember: "unknown member";
			case AmbiguousFunctionCall: "ambiguous function";
			case AmbiguousFunctionCall3: "ambiguous function";
			case AmbiguousFunctionCallMulti: "ambiguous function";

			case CannotDetermineVariableType: "cannot determine type";
			case CannotAssignThisTypeToThatType: "cannot assign different types";
			case CannotAssignToConst: "cannot assign to const";
			case CannotAssignNullToNonOptional: "cannot assign null";

			case ExpectedFunctionParameterName: "expected name here";

			case InconsistentIndent: "inconsistent indent";

			case ExpectedCondition: "expected condition";

			case GetRequiresNoArguments: "cannot accept arguments";
			case GetRequiresAReturn: "type required";
			case SetRequiresOneArgument: "exactly one argument required";

			case ConstructorRequiresNoReturn: "invalid return";
			case DestructorRequiresNoReturn: "invalid return";
			case DestructorRequiresNoArguments: "invalid arguments";
			case InvalidFunctionAttributeForConstructor: "invalid attribute";
			case InvalidFunctionAttributeForDestructor: "invalid attribute";

			case WrongNumberOfArgumentsForOperator: "wrong number of arguments";
			case InvalidFunctionAttributeForOperator: "invalid attribute";

			case ExpectedType: "expected type here";
			case InvalidTypeForAttribute: "invalid type for attribute";
			case UnknownAttribute: "unknown attribute";
			case AttributeArgumentsMismatch: "invalid arguments";
			case MissingCompilerAttributeParameter: "missing compiler attribute parameter";
			case TypeRequiredOnExtern: "type required";
			case InvalidExpressionOnExtern: "expression invalid";
			case InvalidFunctionContentOnExtern: "extern function shouldn't have code";

			case MissingFunctionParameter: "missing function parameter";
			case CannotPassThisForThat: "incorrect type passed";
			case TooManyFunctionParametersProvided: "too many parameters provided";
			case ClassHasNoConstructors: "no constructors available";

			case InterpreterUnknownLiteral: "unknown value";
			case InterpreterLiteralListValuesDoNotMatch: "list value types do not match";
			case InterpreterInvalidLExpr: "invalid lexpr";
			case InterpreterCannotAssignDifferentTypes: "cannot assign mismatched types";
			case InterpreterMustReturnBool: "expression doesn't bool";
			case InterpreterCannotCallType: "cannot call variable";
			case InterpreterArrayAccessExpectsOneNumber: "single number expected";

			case InterpreterAccessOutsideStringSize: "accessed outside string size";
			case InterpreterAccessOutsideArraySize: "accessed outside array size";

			case InterpreterInvalidAccessor: "invalid accessor value";

			case InvalidThisOrSelf: "invalid 'this'";

			case MustUseClassTypeOnExtendsGenericDescriber: "cannot extend this type";
			case TooManyTemplateParameters: "too many template parameters";
			case TypeDoesNotHaveTemplate: "type parameters not required";
			case TypeDoesNotMeetRequirement: "type fails requirements";
			case NotEnoughTemplateParameters: "not enough template parameters";
			case FunctionRequiresTypeArguments: "type arguments required";
			case ClassRequiresTypeArguments: "type arguments required";

			case CannotDetermineParameterType: "type cannot be determined";

			case ReturnedTypeDoesNotMatchReturnType: "type does not match return type";
			case ReturnExpressionExpected: "return expression expected";
			case NoReturnExpressionExpected: "no expression should be present";
			case NoReturnOnFunction: "function missing return statement";

			case TypeCannotBeExtended: "'%1' cannot be extended";
			case InvalidVariableType: "not a valid variable type";
			case InvalidFunctionParameterType: "not a valid parameter type";
			case InvalidFunctionReturnType: "not a valid return type";

			case JsCannotUseDestructor: "cannot use destructor in JS";
			case JsCannotHaveMultipleConstructors: "cannot use multiple constructors in JS";

			default: "";
		}
	}
}
