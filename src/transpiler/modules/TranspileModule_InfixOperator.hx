package transpiler.modules;

using parsers.expr.TypedExpression;
import parsers.expr.InfixOperator;

import transpiler.modules.TranspileModule_Expression;

class TranspileModule_InfixOperator {
	public static function transpile(op: InfixOperator, lexpr: TypedExpression, rexpr: TypedExpression): String {
		if(op.op == ".") {
			return transpileAccess(lexpr, rexpr);
		}
		return transpileNormal(op, lexpr, rexpr);
	}

	public static function transpileAccess(lexpr: TypedExpression, rexpr: TypedExpression): String {
		final type = lexpr.getType();
		var opText = ".";
		switch(type.type) {
			case Namespace(_) | TypeSelf(_): opText = "::";
			case Pointer(_): opText = "->";
			default: {}
		}
		final left = TranspileModule_Expression.transpileExpr(lexpr);
		final right = TranspileModule_Expression.transpileExpr(rexpr);
		return left + opText + right;
	}

	public static function transpileNormal(op: InfixOperator, lexpr: TypedExpression, rexpr: TypedExpression): String {
		final left = TranspileModule_Expression.transpileExpr(lexpr);
		final right = TranspileModule_Expression.transpileExpr(rexpr);
		if(usePadding(op)) {
			return left + " " + op.op + " " + right;
		}
		return left + op.op + right;
	}

	public static function usePadding(op: InfixOperator): Bool {
		return op.op != "." && op.op != "->" && op.op != "::";
	}
}
