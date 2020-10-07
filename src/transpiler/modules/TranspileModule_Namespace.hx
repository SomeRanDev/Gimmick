package transpiler.modules;

import basic.Ref;

import ast.scope.members.NamespaceMember;

import transpiler.Transpiler;

class TranspileModule_Namespace {
	public static function transpile(namespace: Ref<NamespaceMember>, transpiler: Transpiler) {
		final sourceFile = @:privateAccess transpiler.sourceFile;
		sourceFile.addContent("namespace " + namespace.get().name + " {");
		final t = Transpiler.extend(namespace.get().members, transpiler);
		t.transpile();
		sourceFile.addContent("}");
	}
}
