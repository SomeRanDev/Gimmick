package ast.scope.members;

import parsers.Parser;

enum FunctionOption {
	Inline;
	Static;
	Const;
	Virtual;
	Override;
	Inject;
}

class FunctionOptionHelper {
	public static function parseFunctionOptions(parser: Parser): Array<FunctionOption> {
		final result: Array<FunctionOption> = [];
		var word = null;
		while(true) {
			parser.parseWhitespaceOrComments();
			word = parser.parseMultipleWords(["inline", "static", "const", "virtual", "override", "inject"]);
			if(word != null) {
				final option = stringToOption(word);
				if(option != null) {
					result.push(option);
					continue;
				}
			}
			break;
		}
		return result;
	}

	public static function stringToOption(str: String): Null<FunctionOption> {
		return switch(str) {
			case "inline": Inline;
			case "static": Static;
			case "const": Const;
			case "virtual": Virtual;
			case "override": Override;
			case "inject": Inject;
			default: null;
		}
	}

	public static function optionToString(option: FunctionOption): String {
		return switch(option) {
			case Inline: "inline";
			case Static: "static";
			case Const: "const";
			case Virtual: "virtual";
			case Override: "override";
			case Inject: "";
			default: null;
		}
	}

	public static function classOnly(option: FunctionOption): Bool {
		return switch(option) {
			case Static | Virtual | Override: true;
			default: false;
		}
	}

	public static function validJs(option: FunctionOption): Bool {
		return switch(option) {
			case Static: true;
			default: false;
		}
	}

	public static function shouldAppendCpp(option: FunctionOption): Bool {
		return switch(option) {
			case Const | Override: true;
			default: false;
		}
	}

	public static function decorateFunctionHeader(str: String, options: Array<FunctionOption>, isJs: Bool) {
		var prepend = [];
		var append = [];
		for(opt in options) {
			if(!isJs || validJs(opt)) {
				final optStr = optionToString(opt);
				if(shouldAppendCpp(opt)) {
					append.push(optStr);
				} else {
					prepend.push(optStr);
				}
			}
		}
		if(prepend.length > 0) prepend.push("");
		if(append.length > 0) append.insert(0, "");
		return prepend.join(" ") + str + append.join(" ");
	}
}
