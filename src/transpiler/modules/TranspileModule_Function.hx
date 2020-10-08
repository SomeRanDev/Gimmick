package transpiler.modules;

import basic.Ref;

import ast.scope.members.FunctionMember;

import transpiler.modules.TranspileModule_Expression;
import transpiler.modules.TranspileModule_Type;

class TranspileModule_Function {
	public static function transpile(func: Ref<FunctionMember>, transpiler: Transpiler) {
		final data = func.get();
		final type = data.type.get();
		var result = TranspileModule_Type.transpile(type.returnType) + " " + data.name + "() {\n";
		for(e in data.exprMembers) {
			result += "\t" + TranspileModule_Expression.transpileExprMember(e, transpiler.context) + "\n";
		}
		result += "}";
		
		transpiler.addSourceContent(result);
	}
}
