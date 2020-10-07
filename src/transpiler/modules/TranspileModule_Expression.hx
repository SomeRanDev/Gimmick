package transpiler.modules;

import parsers.expr.TypedExpression;

import ast.typing.Type;
import ast.scope.ExpressionMember;

import transpiler.modules.TranspileModule_Type;
import transpiler.modules.TranspileModule_InfixOperator;

class TranspileModule_Expression {
	public static function transpile(expr: ExpressionMember): String {
		switch(expr) {
			case Basic(expr): {
				return transpileExpr(expr) + ";";
			}
			case IfStatement(expr, subExpressions, checkTrue): {
				var result = "if(" + transpileExpr(expr) + ") {\n";
				for(e in subExpressions) {
					result += "\t" + transpile(e) + "\n";
				}
				return result;
			}
			case ReturnStatement(expr): {
				return "return " + transpileExpr(expr) + ";";
			}
		}
		return "";
	}

	public static function transpileExpr(expr: TypedExpression): String {
		switch(expr) {
			case Prefix(op, expr, pos, type): {
				return op.op + transpileExpr(expr);
			}
			case Suffix(op, expr, pos, type): {
				return transpileExpr(expr) + op.op;
			}
			case Infix(op, lexpr, rexpr, pos, type): {
				return TranspileModule_InfixOperator.transpile(op, lexpr, rexpr);
			}
			case Value(literal, pos, type): {
				switch(literal) {
					case Name(name): {
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
							result.push(transpileExpr(e));
						}
						return "{ " + result.join(", ") + "}";
					}
					case Tuple(expressions): {
						final result = [];
						for(e in expressions) {
							result.push(transpileExpr(e));
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
