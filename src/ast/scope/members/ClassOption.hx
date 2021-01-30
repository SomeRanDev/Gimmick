package ast.scope.members;

import parsers.Parser;

enum ClassOption {
	Extern;
}

class ClassOptionHelper {
	public static function parseClassOptions(parser: Parser): Array<ClassOption> {
		final result: Array<ClassOption> = [];
		var word = null;
		while(true) {
			parser.parseWhitespaceOrComments();
			word = parser.parseMultipleWords(["extern"]);
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

	public static function stringToOption(str: String): Null<ClassOption> {
		return switch(str) {
			case "extern": Extern;
			default: null;
		}
	}

	public static function optionToString(option: ClassOption): String {
		return switch(option) {
			case Extern: "";
			default: null;
		}
	}
}
