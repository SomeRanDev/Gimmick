package transpiler.modules;

import basic.Ref;

import ast.scope.ScopeMember;
import ast.scope.members.FunctionMember;

import transpiler.modules.TranspileModule_Expression;
import transpiler.modules.TranspileModule_Type;

class TranspileModule_Function {
	public static function transpile(func: Ref<FunctionMember>, transpiler: Transpiler) {
		final data = func.get();
		final type = data.type.get();
		final funcStart = if(transpiler.context.isCpp()) {
			TranspileModule_Type.transpile(type.returnType);
		} else {
			"function";
		};
		final functionDeclaration = funcStart + " " + data.name + "()";
		if(transpiler.context.isCpp()) {
			transpiler.addHeaderContent(functionDeclaration + ";");
		}
		var result = functionDeclaration + " {\n";
		for(e in data.members) {
			result += "\t" + transpileFunctionMember(e, transpiler.context) + "\n";
		}
		result += "}";
		
		transpiler.addSourceContent(result);
	}

	public static function transpileFunctionMember(member: ScopeMember, context: TranspilerContext): String {
		switch(member) {
			case Variable(variable): {
				return TranspileModule_Variable.transpileVariableSource(variable, context);
			}
			case Function(func): {
				// TODO: function inside function
				//TranspileModule_Function.transpile(func, this);
			}
			case Expression(expr): {
				return TranspileModule_Expression.transpileExprMember(expr, context);
			}
			default: {}
		}
		return "";
	}
}
