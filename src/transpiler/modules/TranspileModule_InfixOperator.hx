package transpiler.modules;

using parsers.expr.TypedExpression;
import parsers.expr.InfixOperator;
import parsers.expr.Literal;
import parsers.expr.CallOperator.CallOperators;

import ast.typing.Type;

import transpiler.TranspilerContext;
import transpiler.modules.TranspileModule_Expression;

class TranspileModule_InfixOperator {
	public static function transpile(op: InfixOperator, lexpr: TypedExpression, rexpr: TypedExpression, transpiler: Transpiler) {
		transpiler.addSourceContent(transpileInfix(op, lexpr, rexpr, transpiler.context));
	}

	public static function transpileInfix(op: InfixOperator, lexpr: TypedExpression, rexpr: TypedExpression, context: TranspilerContext): String {
		if(op.op == ".") {
			return transpileAccess(lexpr, rexpr, context);
		} else if(op.op == "=") {
			return transpileAssign(lexpr, rexpr, context);
		}
		return transpileNormal(op, lexpr, rexpr, context);
	}

	public static function transpileAccess(lexpr: TypedExpression, rexpr: TypedExpression, context: TranspilerContext): String {
		final type = lexpr.getType();
		var opText = ".";
		if(context.isCpp()) {
			switch(type.type) {
				case Namespace(_) | TypeSelf(_): opText = "::";
				case Pointer(_): opText = "->";
				default: {}
			}
		} else if(context.isJs()) {
			switch(type.type) {
				case Pointer(_): opText = ".ptr.";
				case Reference(_): opText = ".ref.";
				default: {}
			}
		}
		final left = TranspileModule_Expression.transpileExpr(lexpr, context);
		final right = TranspileModule_Expression.transpileExpr(rexpr, context);
		return left + opText + right;
	}

	public static function transpileAssign(lexpr: TypedExpression, rexpr: TypedExpression, context: TranspilerContext): String {
		switch(lexpr) {
			case Value(literal, pos, _): {
				switch(literal) {
					case GetSet(getsetMember): {
						final setFunc = getsetMember.set;
						if(setFunc != null) {
							final valueType = Type.Function(setFunc.type, null);
							final setFuncLiteral = TypedExpression.Value(Literal.Function(setFunc), pos, valueType);
							final returnType = setFunc.type.get().returnType;
							final callExpr = Call(CallOperators.Call, setFuncLiteral, [rexpr], pos, returnType);
							return TranspileModule_Expression.transpileExpr(callExpr, context);
						}
					}
					default: {}
				}
			}
			default: {}
		}
		return transpileNormal(InfixOperators.Assignment, lexpr, rexpr, context);
	}

	public static function transpileNormal(op: InfixOperator, lexpr: TypedExpression, rexpr: TypedExpression, context: TranspilerContext): String {
		final left = TranspileModule_Expression.transpileExpr(lexpr, context);
		final right = TranspileModule_Expression.transpileExpr(rexpr, context);
		if(usePadding(op)) {
			return left + " " + op.op + " " + right;
		}
		return left + op.op + right;
	}

	public static function usePadding(op: InfixOperator): Bool {
		return op.op != "." && op.op != "->" && op.op != "::";
	}
}
