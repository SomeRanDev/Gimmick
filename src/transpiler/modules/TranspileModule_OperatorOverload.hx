package transpiler.modules;

import ast.scope.members.FunctionMember;

class TranspileModule_OperatorOverload {
	public static function transpileOperatorOverload(func: FunctionMember, context: TranspilerContext): Bool {
		final op = func.isOperator();
		if(op != null) {
			switch(op.type) {
				case CppOperatorOverload: {
					if(context.isCpp()) return true;
				}
				case CppOperatorOverloadWithOneArg: {
					if(context.isCpp() && func.type.get().arguments.length == 1) return true;
				}
				default: {}
			}
		}
		return false;
	}
	public static function getOperatorFunctionName(func: FunctionMember, context: TranspilerContext): Null<String> {
		final op = func.isOperator();
		if(op != null) {
			return transpileOperatorOverload(func, context) ? ("operator" + op.op) : op.name;
		}
		return null;
	}
}
