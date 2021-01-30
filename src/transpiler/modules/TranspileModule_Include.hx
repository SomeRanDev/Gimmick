package transpiler.modules;

import basic.Ref;

class TranspileModule_Include {
	public static function transpile(path: String, brackets: Bool, header: Bool, transpiler: Transpiler) {
		if(transpiler.context.isCpp()) {
			final result = "#include " + (brackets ? '<$path>' : '"$path"');
			if(header) {
				transpiler.addHeaderContent(result);
			} else {
				transpiler.addSourceContent(result);
			}
		}
	}
}
