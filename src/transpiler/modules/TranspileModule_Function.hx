package transpiler.modules;

import basic.Ref;

import ast.scope.members.FunctionMember;

import transpiler.modules.TranspileModule_Expression;
import transpiler.modules.TranspileModule_Type;

class TranspileModule_Function {
	public static function transpile(func: Ref<FunctionMember>): String {
		final data = func.get();
		final type = data.type.get();
		var result = TranspileModule_Type.transpile(type.returnType) + " " + data.name + "() {\n";
		for(e in data.exprMembers) {
			result += "\t" + TranspileModule_Expression.transpile(e) + "\n";
		}
		result += "}";
		return result;
	}
}
