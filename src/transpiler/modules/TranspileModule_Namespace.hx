package transpiler.modules;

import basic.Ref;

import ast.scope.members.NamespaceMember;

import transpiler.Transpiler;
import transpiler.modules.TranspileModule_Variable;

class TranspileModule_Namespace {
	public static function transpile(namespace: Ref<NamespaceMember>, transpiler: Transpiler) {
		final sourceFile = transpiler.sourceFile;
		final name = namespace.get().name;

		if(transpiler.context.isCpp()) {
			transpiler.addSourceAndHeaderContent("namespace " + name + " {");
		} else if(transpiler.context.isJs()) {
			final prefix = TranspileModule_Variable.getVariableAndNamespacePrefixJs(transpiler.context);
			final varOp = prefix == null ? "var " : "";
			final fullName = prefix == null ? name : prefix + name;
			transpiler.addSourceContent(varOp + fullName + " = " + fullName + " || {};\n");
		}

		transpiler.context.pushNamespace(name);
		final t = Transpiler.extend(namespace.get().members, transpiler);
		t.setInitialMemberIndex(1);
		t.transpile();
		transpiler.context.popNamespace();

		if(transpiler.context.isCpp()) {
			if(t.finalMemberIndex() != 1) {
				transpiler.addSourceAndHeaderContent("");
			}
			transpiler.addSourceAndHeaderContent("}");
		}
	}
}
