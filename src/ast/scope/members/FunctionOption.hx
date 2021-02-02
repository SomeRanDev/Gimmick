package ast.scope.members;

import basic.Tuple2;

import parsers.Parser;
import parsers.expr.Position;

enum FunctionOption {
	Inline;
	Static;
	Const;
	Virtual;
	Abstract;
	Override;
	Inject;
	Extern;
}

class FunctionOptionHelper {
	public static function parseFunctionOptions(parser: Parser): Array<Tuple2<FunctionOption, Position>> {
		final result: Array<Tuple2<FunctionOption, Position>> = [];
		var word = null;
		while(true) {
			parser.parseWhitespaceOrComments();
			final initialPos = parser.getIndex();
			word = parser.parseMultipleWords(["inline", "static", "const", "virtual", "abstract", "override", "inject", "extern"]);
			if(word != null) {
				final pos = parser.makePosition(initialPos);
				final option = stringToOption(word);
				if(option != null) {
					result.push(new Tuple2<FunctionOption, Position>(option, pos));
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
			case "abstract": Abstract;
			case "override": Override;
			case "inject": Inject;
			case "extern": Extern;
			default: null;
		}
	}

	public static function optionToString(option: FunctionOption): String {
		return switch(option) {
			case Inline: "inline";
			case Static: "static";
			case Const: "const";
			case Virtual: "virtual";
			case Abstract: "virtual";
			case Override: "override";
			case Inject: "";
			case Extern: "";
			default: null;
		}
	}

	public static function classOnly(option: FunctionOption): Bool {
		return switch(option) {
			case Static | Virtual | Abstract | Override: true;
			default: false;
		}
	}

	public static function constructorValid(option: FunctionOption): Bool {
		return false;
	}

	public static function destructorValid(option: FunctionOption): Bool {
		return switch(option) {
			case Virtual: true;
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
