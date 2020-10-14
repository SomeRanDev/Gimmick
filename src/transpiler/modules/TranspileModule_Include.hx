package transpiler.modules;

import basic.Ref;

class TranspileModule_Include {
	public static function transpile(path: String, brackets: Bool, transpiler: Transpiler) {
		if(transpiler.context.isCpp()) {
			transpiler.addSourceContent("#include " + (brackets ? '<$path>' : '"$path"'));
		}
	}
}
