package transpiler.modules;

import basic.Ref;

class TranspileModule_Include {
	public static function transpile(path: String, brackets: Bool): String {
		return "#include " + (brackets ? '<$path>' : '"$path"');
	}
}
