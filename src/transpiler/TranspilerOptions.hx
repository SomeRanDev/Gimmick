package transpiler;

import io.CompilerArgumentParser;

class TranspilerOptions {
	public static var pragmaHeaderGuard(default, null): Bool = false;
	public static var hppHeaderExtension(default, null): Bool = false;

	public static function init(argParser: CompilerArgumentParser) {
		pragmaHeaderGuard = argParser.contains("cppPragmaGuard");
		hppHeaderExtension = argParser.contains("hppExtension");
	}
}
