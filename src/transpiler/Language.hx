package transpiler;

import io.CompilerArgumentParser;

import transpiler.TranspilerOptions;

enum Language {
	Cpp;
	Js;
}

class LanguageHelper {
	public static function getLanguage(argParser: CompilerArgumentParser): Language {
		return argParser.contains("js") ? Js : Cpp;
	}

	public static function isCpp(language: Language): Bool {
		return switch(language) {
			case Cpp: true;
			default: false;
		}
	}

	public static function isJs(language: Language): Bool {
		return switch(language) {
			case Js: true;
			default: false;
		}
	}

	public static function sourceFileExtension(language: Language): String {
		return switch(language) {
			case Cpp: ".cpp";
			case Js: ".js";
		}
	}

	public static function headerFileExtension(language: Language): String {
		return switch(language) {
			case Cpp: TranspilerOptions.hppHeaderExtension ? ".hpp" : ".h";
			default: "";
		}
	}
}
