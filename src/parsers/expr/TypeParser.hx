package parsers.expr;

import ast.typing.Type;
import ast.typing.FunctionType;
import ast.typing.FunctionArgument;

import parsers.Parser;
import parsers.error.Error;
import parsers.error.ErrorType;

class TypeParser {
	var parser: Parser;
	var allowUnknownNamed: Bool;

	public function new(parser: Parser, allowUnknownNamed: Bool = true) {
		this.parser = parser;
		this.allowUnknownNamed = allowUnknownNamed;
	}

	public function parseType(): Null<Type> {
		parser.parseWhitespaceOrComments();

		final isConst = checkConst();

		parser.parseWhitespaceOrComments();

		final typeListStart = parser.getIndex();
		var typeList: Null<Array<Type>> = parseAllTypesListed();
		typeList = constructTypeFromList(typeList, typeListStart);

		if(typeList == null) {
			return null;
		}

		if(typeList.length == 1) {
			final result = typeList[0];
			if(isConst) {
				result.setConst();
			}
			return result;
		}

		return null;
	}

	function checkConst(): Bool {
		if(parser.parseWord("const")) {
			return true;
		}
		return false;
	}

	function parseAllTypesListed(): Array<Type> {
		final result: Array<Type> = [];
		var first = true;
		while(true) {
			parser.parseWhitespaceOrComments(true);
			final initialIndex = parser.getIndex();
			final type = parseTypeName(first);
			first = false;
			if(type != null) {
				result.push(type);
			} else {
				break;
			}
		}
		return result;
	}

	function constructTypeFromList(typeList: Array<Type>, typeListStart: Int): Null<Array<Type>> {
		while(typeList.length > 1) {
			final param = typeList.shift();
			final type = typeList.shift();
			if(param != null && type != null) {
				type.appendTypeParam(param);
			}
			if(type == null) {
				Error.addError(ErrorType.InvalidTypeParameter, parser, typeListStart);
				return null;
			} else {
				typeList.insert(0, type);
			}
		}
		return typeList;
	}

	function parseTypeName(first: Bool): Null<Type> {
		final initialState = parser.saveParserState();
		var type = null;

		var check = 0;
		final startPos = parser.getIndex();
		while(type == null && check <= 3) {
			switch(check) {
				case 0: if(first) type = checkTuple();
				case 1: type = checkExtern();
				case 2: if(first) type = checkFunction();
				case 3: {
					final name = parser.parseNextVarName();
					if(name != null) {
						type = parser.scope.findTypeFromName(name);
						if(allowUnknownNamed && type == null) {
							type = Type.UnknownNamed(name);
						}
					}
				}
			}
			check++;
		}

		if(type != null) {
			type.setPosition(parser.makePosition(startPos));
		}
		
		if(type != null) {

			final preTypeParams = parser.saveParserState();
			parser.parseWhitespaceOrComments();
			var typeParams = parseTypeParameters();
			if(typeParams != null) {
				type.setTypeParams(typeParams);
			} else {
				parser.restoreParserState(preTypeParams);
			}

			if(type != null) {
				final preOptional = parser.saveParserState();
				parser.parseWhitespaceOrComments();
				if(parser.parseNextContent("?")) {
					type.setOptional();
				} else {
					parser.restoreParserState(preOptional);
				}
			}

			return type;
		} else {
			parser.restoreParserState(initialState);
		}
		return null;
	}

	function checkTuple(): Null<Type> {
		if(parser.checkAhead("(")) {
			final tupleTypes = parseTypeList(parser, "(", ")", ",");
			if(tupleTypes != null) {
				if(tupleTypes.length == 0) {
					return Type.Void();
				}
				parser.parseWhitespaceOrComments();
				return Type.Tuple(tupleTypes);
			}
		}
		return null;
	}

	function checkExtern(): Null<Type> {
		if(parser.parseWord("ext")) {
			parser.parseWhitespaceOrComments();
			final extName = parser.parseNextVarName();
			if(extName != null) {
				return Type.External(extName, null);
			} else {
				Error.addError(ExpectedExternalName, parser, parser.getIndexFromLine());
			}
		}
		return null;
	}

	function checkFunction(): Null<Type> {
		if(parser.parseWord("func")) {
			parser.parseWhitespaceOrComments();
			final funcType = parseFunctionTypeData(parser);
			return Type.Function(funcType.getRef(), null);
		}
		return null;
	}

	function parseTypeParameters(): Null<Array<Type>> {
		return parseTypeList(parser, "<", ">", ",");
	}

	public static function parseFunctionTypeData(parser: Parser): FunctionType {
		var params = null;
		var returnType = null;
		if(parser.checkAhead("(")) {
			params = parseTypeList(parser, "(", ")", ",", true);
		}
		if(params == null) {
			params = [];
		}
		parser.parseWhitespaceOrComments();
		if(parser.parseNextContent("->")) {
			parser.parseWhitespaceOrComments();
			returnType = parser.parseType();
		}
		if(returnType == null) {
			returnType = Type.Void();
		}
		return new FunctionType(params.map(p -> new FunctionArgument("", p, null)), returnType);
	}

	public static function parseTypeList(parser: Parser, start: String, end: String, separator: String, allowEmpty: Bool = false): Null<Array<Type>> {
		final startState = parser.saveParserState();
		var result: Null<Array<Type>> = null;
		var success = false;
		if(parser.parseNextContent(start)) {
			result = [];
			while(true) {
				parser.parseWhitespaceOrComments();
				final typeStart = parser.getIndexFromLine();
				final subtype = parser.parseType();
				if(subtype != null) {
					result.push(subtype);
					parser.parseWhitespaceOrComments();
					if(parser.parseNextContent(separator)) {
					} else if(parser.parseNextContent(end)) {
						success = true;
						break;
					} else {
						Error.addError(ErrorType.UnexpectedCharacter, parser, parser.getIndexFromLine());
						return null;
					}
				} else {
					if(allowEmpty && result.length == 0) {
						if(parser.parseNextContent(end)) {
							success = true;
							break;
						}
					}
					Error.addError(ErrorType.UnknownType, parser, typeStart);
					break;
				}
			}
		}
		if(!success) {
			parser.restoreParserState(startState);
			return null;
		}
		return result;
	}
}
