package transpiler.modules;

import parsers.expr.TypedExpression;

import ast.typing.Type;
import ast.scope.ExpressionMember;

import transpiler.TranspilerContext;
import transpiler.modules.TranspileModule_Type;
import transpiler.modules.TranspileModule_InfixOperator;

class TranspileModule_Expression {
	public static function transpile(expr: ExpressionMember, transpiler: Transpiler) {
		transpiler.addSourceContent(transpileExprMember(expr, transpiler.context));
	}

	public static function transpileExprMember(expr: ExpressionMember, context: TranspilerContext): String {
		switch(expr) {
			case Basic(expr): {
				return transpileExpr(expr, context) + ";";
			}
			case IfStatement(expr, subExpressions, checkTrue): {
				var result = "if(" + transpileExpr(expr, context) + ") {\n";
				for(e in subExpressions) {
					result += "\t" + transpileExprMember(e, context) + "\n";
				}
				return result;
			}
			case ReturnStatement(expr): {
				return "return " + transpileExpr(expr, context) + ";";
			}
		}
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
