package transpiler.modules;

using parsers.expr.TypedExpression;
import parsers.expr.InfixOperator;
import parsers.expr.Literal;
import parsers.expr.CallOperator.CallOperators;

import ast.typing.Type;
import ast.scope.ScopeMember;

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
		var opText = getDotAccessor(type, context);
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

		// TODO: do conversion earlier
		/*
		final scopeMem = lexpr.getType().findOverloadedInfixOperator(op, rexpr.getType());
		if(scopeMem != null) {
			switch(scopeMem.type) {
				case ScopeMemberType.InfixOperator(_, func): {
					final funcMem = func.get();
					if(!TranspileModule_OperatorOverload.transpileOperatorOverload(funcMem, context)) {
						final name = TranspileModule_OperatorOverload.getOperatorFunctionName(funcMem, context);
						final dot = getDotAccessor(lexpr.getType(), context);
						return left + dot + name + "(" + right + ")";
					}
				}
				default: {}
			}
		}
		*/

		if(usePadding(op)) {
			return left + " " + op.op + " " + right;
		}
		return left + op.op + right;
	}

	public static function usePadding(op: InfixOperator): Bool {
		return op.op != "." && op.op != "->" && op.op != "::";
	}

	public static function getDotAccessor(type: Type, context: TranspilerContext): String {
		if(context.isCpp()) {
			switch(type.type) {
				case Namespace(_) | TypeSelf(_): return "::";
				case Pointer(_): return "->";
				default: {}
			}
		}
		return ".";
	}
}
