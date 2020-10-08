package transpiler.modules;

import basic.Ref;

import ast.scope.members.NamespaceMember;

import transpiler.Transpiler;

class TranspileModule_Namespace {
	public static function transpile(namespace: Ref<NamespaceMember>, transpiler: Transpiler) {
		final sourceFile = @:privateAccess transpiler.sourceFile;
		final name = namespace.get().name;
		sourceFile.addContent("namespace " + name + " {\n");
		transpiler.context.pushNamespace(name);
		final t = Transpiler.extend(namespace.get().members, transpiler);
		t.setInitialMemberIndex(1);
		t.transpile();
		transpiler.context.popNamespace();
		if(t.finalMemberIndex() != 1) {
			sourceFile.addContent("\n");
		}
		sourceFile.addContent("}\n");
	}
}
