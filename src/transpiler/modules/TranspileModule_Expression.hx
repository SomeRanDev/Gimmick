package transpiler.modules;

import parsers.expr.TypedExpression;
import parsers.expr.CallOperator.CallOperators;
import parsers.expr.QuantumExpression.QuantumExpressionInternal;

import ast.typing.Type;

using ast.scope.ScopeMember;
using ast.scope.ExpressionMember;

import transpiler.TranspilerContext;
import transpiler.modules.TranspileModule_Type;
import transpiler.modules.TranspileModule_InfixOperator;

class TranspileModule_Expression {
	public static function transpile(expr: ExpressionMember, transpiler: Transpiler) {
		transpiler.addSourceContent(transpileExprMember(expr, transpiler.context, 0));
	}

	public static function transpileExprMember(expr: ExpressionMember, context: TranspilerContext, tabLevel: Int): String {
		switch(expr) {
			case Basic(expr): {
				return switch(expr) {
					case Untyped(_): "";
					case Typed(texpr): transpileExpr(texpr, context) + ";";
				}
			}
			case Pass: return "";
			case Break: return "break;";
			case Continue: return "continue;";
			case Scope(exprs): {
				return transpileScope(exprs, context, tabLevel);
			}
			case Loop(expr, subExpressions, checkTrue): {
				if(expr == null) {
					return "while(true) " + transpileScope(subExpressions, context, tabLevel);
				} else {
					final exprStr = switch(expr) {
						case Untyped(_): null;
						case Typed(texpr): transpileExpr(texpr, context);
					}
					if(exprStr == null) return "";
					return "while(" + exprStr + ") " + transpileScope(subExpressions, context, tabLevel);
				}
			}
			case IfStatement(expr, subExpressions, checkTrue): {
				final exprStr = switch(expr) {
					case Untyped(_): null;
					case Typed(texpr): transpileExpr(texpr, context);
				}
				if(exprStr == null) return "";
				var result = "if(" + exprStr + ") " + transpileScope(subExpressions, context, tabLevel);
				return result;
			}
			case IfElseStatement(ifExpr, subExpressions): {
				var result = transpileExprMember(ifExpr, context, tabLevel);
				result += " else " + transpileScope(subExpressions, context, tabLevel);
				return result;
			}
			case IfElseIfChain(ifExprs, elseExpressions): {
				var result = "";
				for(i in 0...ifExprs.length) {
					result += transpileExprMember(ifExprs[i], context, tabLevel);
					if(i < ifExprs.length - 1) result += " else ";
				}
				if(elseExpressions != null) {
					result += " else " + transpileScope(elseExpressions, context, tabLevel);
				}
				return result;
			}
			case ReturnStatement(expr): {
				final exprStr = switch(expr) {
					case Untyped(_): null;
					case Typed(texpr): transpileExpr(texpr, context);
				}
				if(exprStr == null) return "";
				return "return " + exprStr + ";";
			}
			default: {}
		}
		return "";
	}

	public static function transpileScope(exprs: Array<ScopeMember>, context: TranspilerContext, tabLevel: Int): String {
		var result = "{\n";
		var tabs = "";
		for(i in 0...tabLevel) tabs += "\t";
		for(e in exprs) {
			if(e.isPass()) continue;
			result += tabs + "\t" + TranspileModule_Function.transpileFunctionMember(e, context, tabLevel) + "\n";
		}
		result += tabs + "}";
		return result;
	}

	public static function transpileExpr(expr: TypedExpression, context: TranspilerContext): String {
		switch(expr) {
			case Prefix(op, expr, pos, type): {
				return op.op + transpileExpr(expr, context);
			}
			case Suffix(op, expr, pos, type): {
				return transpileExpr(expr, context) + op.op;
			}
			case Infix(op, lexpr, rexpr, pos, type): {
				return TranspileModule_InfixOperator.transpileInfix(op, lexpr, rexpr, context);
			}
			case Call(op, expr, params, pos, type): {
				final paramStrings: Array<String> = params.map(p -> transpileExpr(p, context));
				return transpileExpr(expr, context) + op.op + paramStrings.join(", ") + op.endOp;
			}
			case Value(literal, pos, type): {
				switch(literal) {
					case Name(name, namespaces): {
						final nsAccessOp = context.isJs() ? "." : "::";
						if(context.isJs()) {
							// Always must use "namespaces" when referencing variables in JS.
							if(namespaces != null && context.matchesNamespace(namespaces)) {
								return context.reverseJoinArray(namespaces, nsAccessOp) + nsAccessOp + name;
							}
						}
						// If this "variable" is outside the namespace declaration, add them.
						// Usually it shouldn't be, but there are exceptions such as main functions.
						if(namespaces != null && !context.matchesNamespace(namespaces)) {
							return context.reverseJoinArray(namespaces, nsAccessOp) + nsAccessOp + name;
						}
						return name;
					}
					case Variable(varMember): {
						return transpileExpr(Value(Name(varMember.name, varMember.getNamespaces()), pos, type), context);
					}
					case Function(funcMember): {
						return transpileExpr(Value(Name(funcMember.name, funcMember.getNamespaces()), pos, type), context);
					}
					case GetSet(getsetMember): {
						final getFunc = getsetMember.get;
						if(getFunc != null) {
							final valueType = Type.Function(getFunc.type, null);
							final setFuncLiteral = TypedExpression.Value(Literal.Function(getFunc), pos, valueType);
							final returnType = getFunc.type.get().returnType;
							final callExpr = Call(CallOperators.Call, setFuncLiteral, [], pos, returnType);
							return TranspileModule_Expression.transpileExpr(callExpr, context);
						}
					}
					case Null: {
						return context.isJs() ? "null" : "nullptr";
					}
					case Boolean(value): {
						return value ? "true" : "false";
					}
					case Number(number, format, type): {
						return number;
					}
					case String(content, isMultiline, isRaw): {
						if(isRaw) {
							return "R\"(" + content + ")\"";
						} else if(isMultiline) {
							final regex = ~/\r?\n\r?/g;
							return "\"" + regex.replace(content, "\\n\\\n") + "\"";
						} else {
							return "\"" + content + "\"";
						}
					}
					case List(expressions): {
						final result = [];
						for(e in expressions) {
							result.push(transpileExpr(e, context));
						}
						final resultStr = result.join(", ");
						if(context.isJs()) {
							return "[" + resultStr + "]";
						}
						return "{" + resultStr + "}";
					}
					case Tuple(expressions): {
						final result = [];
						for(e in expressions) {
							result.push(transpileExpr(e, context));
						}
						final resultStr = result.join(", ");
						if(context.isJs()) {
							return "[" + resultStr + "]";
						}
						return "std::make_tuple(" + resultStr + ")";
					}
					case TypeName(type): {
						return TranspileModule_Type.transpile(type);
					}
					case EnclosedExpression(expr): {
						return "(" + transpileExpr(expr, context) + ")";
					}
				}
			}
		}
		return "";
	}
}
