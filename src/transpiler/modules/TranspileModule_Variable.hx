package transpiler.modules;

import basic.Ref;

import ast.scope.members.VariableMember;

import transpiler.modules.TranspileModule_Expression;
import transpiler.modules.TranspileModule_Type;

class TranspileModule_Variable {
	public static function transpile(variable: Ref<VariableMember>): String {
		final member = variable.get();
		var result = "";
		if(member.isStatic) {
			result += "static ";
		}
		result += TranspileModule_Type.transpile(member.type) + " ";
		result += member.name;
		final assignment = TranspileModule_Type.getDefaultAssignment(member.type);
		final expression = member.expression;
		if(expression != null) {
			result += " = " + TranspileModule_Expression.transpileExpr(expression);
		} else if(assignment != null) {
			result += " = " + assignment;
		}
		result += ";";
		return result;
	}
}
