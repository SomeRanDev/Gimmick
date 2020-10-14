package parsers.expr;

import ast.typing.Type;
import ast.typing.FunctionType;
import ast.typing.FunctionArgument;

import parsers.Parser;

class TypeParser {
	var parser: Parser;

	public function new(parser: Parser) {
		this.parser = parser;
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
		while(true) {
			parser.parseWhitespaceOrComments();
			final initialIndex = parser.getIndex();
			final type = parseTypeName();
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

	function parseTypeName(): Null<Type> {
		final initialIndex = parser.getIndex();
		var type = null;

		var check = 0;
		while(type == null && check <= 3) {
			switch(check) {
				case 0: type = checkTuple();
				case 1: type = checkExtern();
				case 2: type = checkFunction();
				case 3: {
					final name = parser.parseNextVarName();
					if(name != null) {
						type = parser.scope.findTypeFromName(name);
					}
				}
			}
			check++;
		}
		
		if(type != null) {
			parser.parseWhitespaceOrComments();
			var typeParams = parseTypeParameters();
			if(typeParams != null) {
				type.setTypeParams(typeParams);
			}
			if(type != null) {
				parser.parseWhitespaceOrComments();
				if(parser.parseNextContent("?")) {
					type.setOptional();
				}
			}
			return type;
		} else {
			parser.setIndex(initialIndex);
		}
		return null;
	}

	function checkTuple(): Null<Type> {
		if(parser.checkAhead("(")) {
			final tupleTypes = parseTypeList("(", ")", ",");
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
			var params = null;
			var returnType = null;
			if(parser.checkAhead("(")) {
				params = parseTypeList("(", ")", ",", true);
			}
			if(params == null) {
				params = [];
			}
			parser.parseWhitespaceOrComments();
			if(parser.parseNextContent("->")) {
				parser.parseWhitespaceOrComments();
				returnType = parseType();
			}
			if(returnType == null) {
				returnType = Type.Void();
			}
			final funcType = new FunctionType(params.map(p -> new FunctionArgument("", p, null)), returnType);
			return Type.Function(funcType.getRef(), null);
		}
		return null;
	}

	function parseTypeParameters(): Null<Array<Type>> {
		return parseTypeList("<", ">", ",");
	}

	function parseTypeList(start: String, end: String, separator: String, allowEmpty: Bool = false): Null<Array<Type>> {
		var result: Null<Array<Type>> = null;
		if(parser.parseNextContent(start)) {
			result = [];
			while(true) {
				parser.parseWhitespaceOrComments();
				final typeStart = parser.getIndexFromLine();
				final subtype = parseType();
				if(subtype != null) {
					result.push(subtype);
					parser.parseWhitespaceOrComments();
					if(parser.parseNextContent(separator)) {
					} else if(parser.parseNextContent(end)) {
						break;
					} else {
						Error.addError(ErrorType.UnexpectedCharacter, parser, parser.getIndexFromLine());
						return null;
					}
				} else {
					if(allowEmpty && result.length == 0) {
						if(parser.parseNextContent(end)) {
							break;
						}
					}
					Error.addError(ErrorType.UnknownType, parser, typeStart);
					break;
				}
			}
		}
		return result;
	}
}
