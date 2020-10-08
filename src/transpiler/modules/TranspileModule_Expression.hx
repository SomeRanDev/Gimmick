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
			case Value(literal, pos, type): {
				switch(literal) {
					case Name(name, namespaces): {
						// If this "variable" is outside the namespace declaration, add them.
						// Usually it shouldn't be, but there are exceptions such as main functions.
						if(namespaces != null && !context.matchesNamespace(namespaces)) {
							return namespaces.join("::") + "::" + name;
						}
						return name;
					}
					case Null: {
						return "nullptr";
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
						return "{ " + result.join(", ") + "}";
					}
					case Tuple(expressions): {
						final result = [];
						for(e in expressions) {
							result.push(transpileExpr(e, context));
						}
						return "std::make_tuple(" + result.join(", ") + ")";
					}
					case TypeName(type): {
						return TranspileModule_Type.transpile(type);
					}
				}
			}
		}
		return "";
	}
}
