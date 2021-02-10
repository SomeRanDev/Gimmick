package parsers.expr;

using parsers.expr.TypedExpression;

import ast.typing.Type;
import ast.typing.NumberType;
import ast.scope.members.VariableMember;
import ast.scope.members.FunctionMember;
import ast.scope.members.GetSetMember;

enum Literal {
	Name(name: String, namespaces: Null<Array<String>>);
	Null;
	This;
	Boolean(value: Bool);
	Number(number: String, format: NumberLiteralFormat, type: NumberType);
	String(content: String, isMultiline: Bool, isRaw: Bool);
	List(expressions: Array<TypedExpression>);
	Tuple(expressions: Array<TypedExpression>);
	TypeName(type: Type);
	EnclosedExpression(expression: TypedExpression);
	Variable(member: VariableMember);
	Function(member: FunctionMember);
	GetSet(member: GetSetMember);
}

enum NumberLiteralFormat {
	Decimal;
	Hex;
	Binary;
}

class LiteralHelper {
	public static function isConst(literal: Literal): Bool {
		switch(literal) {
			case Null | Boolean(_) | Number(_, _, _) | String(_, _, _): {
				return true;
			}
			case List(exprs): {
				for(e in exprs) {
					if(!e.isConst()) return false;
				}
				return true;
			}
			case Tuple(exprs): {
				for(e in exprs) {
					if(!e.isConst()) return false;
				}
				return true;
			}
			case EnclosedExpression(expression): {
				return expression.isConst();
			}
			case Variable(member): {
				return member.type.isConst;
			}
			default: {}
		}
		return false;
	}

	public static function changeName(literal: Literal, newName: String): Null<Literal> {
		return switch(literal) {
			case Name(name, namespaces): Name(newName, namespaces);
			default: null;
		}
	}
}
