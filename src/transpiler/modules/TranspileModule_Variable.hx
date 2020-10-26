package transpiler.modules;

import basic.Ref;

import ast.scope.members.VariableMember;

import parsers.expr.QuantumExpression;

import transpiler.Transpiler;
import transpiler.modules.TranspileModule_Expression;
import transpiler.modules.TranspileModule_Type;

class TranspileModule_Variable {
	public static function transpile(variable: Ref<VariableMember>, transpiler: Transpiler) {
		final result = transpileVariableSource(variable, transpiler.context);
		transpiler.addSourceContent(result);

		final member = variable.get();
		transpiler.addHeaderContent("extern " + TranspileModule_Type.transpile(member.type) + " " + member.name + ";");
	}

	public static function transpileVariableSource(variable: Ref<VariableMember>, context: TranspilerContext) {
		final member = variable.get();
		var result = "";
		result += makeVariablePrefix(member, context);
		result += member.name;
		final assignment = TranspileModule_Type.getDefaultAssignment(member.type);
		final expression = switch(member.expression) {
			case null: null;
			case Untyped(_): null;
			case Typed(texpr): texpr;
		}
		if(expression != null) {
			result += " = " + TranspileModule_Expression.transpileExpr(expression, context);
		} else if(assignment != null) {
			result += " = " + assignment;
		}
		result += ";";
		return result;
	}

	public static function makeVariablePrefix(member: VariableMember, context: TranspilerContext): String {
		var result = "";
		if(context.isCpp()) {
			if(member.isStatic) {
				result += "static ";
			}
			result += TranspileModule_Type.transpile(member.type) + " ";
		} else if(context.isJs()) {
			final prefix = getVariableAndNamespacePrefixJs(context);
			result += prefix == null ? "var " : prefix;
		}
		return result;
	}

	public static function getVariableAndNamespacePrefixJs(context: TranspilerContext): Null<String> {
		if(context.isTopLevel() && context.hasNamespace()) {
			return context.constructNamespace() + ".";
		}
		return null;
	}
}
