package parsers.expr;

import ast.typing.Type;

using ast.scope.ScopeMember;

import parsers.expr.Expression;
import parsers.expr.Expression.ExpressionHelper;
import parsers.expr.Operator;

class InfixOperator extends Operator {
	public function findReturnType(ltype: Type, rtype: Type): Null<Type> {
		if(isAccessor()) {
			// to access stuff
			switch(ltype.type) {
				case Class(cls, typeParams): {
					switch(rtype.type) {
						case UnknownNamed(name): {
							final member = cls.get().members.find(name);
							if(member != null) {
								return member.getType();
							}
						}
						default: {}
					}
				}
				case String: {
					
				}
				default: {}
			}
		}

		var initialTest = switch(ltype.type) {
			case Void:
				Type.Void();
			case Any | External(_, _):
				Type.Any();
			default: null;
		}
		if(initialTest == null) {
			initialTest = switch(rtype.type) {
				case Void:
					Type.Void();
				case Any | External(_, _):
					Type.Any();
				default: null;
			}
		}
		if(initialTest != null) {
			return initialTest;
		}
		
		// do overloaded stuff

		if(op == "=") {
			return ltype.canBeAssigned(rtype) == null ? ltype : null;
		}

		if((op == "==" || op == "!=") && ltype.baseTypesEqual(rtype)) {
			return ltype;
		}
		if(ltype.bothSameAndNotNull(rtype)) {
			final defaultsTest = switch(ltype.type) {
				case Number(numType): ltype;
				case String: {
					if(op == "+") {
						ltype;
					} else {
						null;
					}
				}
				default: null;
			}

			return defaultsTest;
		}

		return null;
	}

	public function isAccessor(): Bool {
		return op == "." || op == "->";
	}
}

class InfixOperators {
	public static var DotAccess = new InfixOperator(".", 0xf000);
	public static var ArrowAccess = new InfixOperator("->", 0xf000);
	public static var StaticAccess = new InfixOperator("::", 0xf000);

	public static var Multiply = new InfixOperator("*", 0xd000);
	public static var Divide = new InfixOperator("/", 0xd000);
	public static var Mod = new InfixOperator("%", 0xd000);

	public static var Add = new InfixOperator("+", 0xc000);
	public static var Subtract = new InfixOperator("-", 0xc000);

	public static var BitLeft = new InfixOperator("<<", 0xb000);
	public static var BitRight = new InfixOperator(">>", 0xb000);

	public static var ThreeWayComp = new InfixOperator("<=>", 0xa000);

	public static var LessThan = new InfixOperator("<", 0x9000);
	public static var LessThanEqual = new InfixOperator("<=", 0x9000);
	public static var GreaterThan = new InfixOperator(">", 0x9000);
	public static var GreaterThanEqual = new InfixOperator(">=", 0x9000);

	public static var Equals = new InfixOperator("==", 0x8000);
	public static var NotEquals = new InfixOperator("!=", 0x8000);

	public static var BitAnd = new InfixOperator("&", 0x7000);
	public static var BitXOr = new InfixOperator("^", 0x6000);
	public static var BitOr = new InfixOperator("|", 0x5000);

	public static var LogicAnd = new InfixOperator("&&", 0x4000);
	public static var LogicOr = new InfixOperator("||", 0x3000);

	public static var Assignment = new InfixOperator("=", 0x2000);
	public static var AddAssign = new InfixOperator("+=", 0x2000);
	public static var SubAssign = new InfixOperator("-=", 0x2000);
	public static var MultAssign = new InfixOperator("*=", 0x2000);
	public static var DivAssign = new InfixOperator("/=", 0x2000);
	public static var ModAssign = new InfixOperator("%=", 0x2000);
	public static var LeftBitAssign = new InfixOperator("<<=", 0x2000);
	public static var RightBitAssign = new InfixOperator(">>=", 0x2000);
	public static var AndBitAssign = new InfixOperator("&=", 0x2000);
	public static var XOrBitAssign = new InfixOperator("^=", 0x2000);
	public static var OrBitAssign = new InfixOperator("|=", 0x2000);

	public static function all(): Array<InfixOperator> {
		return [
			DotAccess, ArrowAccess, StaticAccess,
			Multiply, Divide, Mod,
			Add, Subtract,
			BitLeft, BitRight,
			ThreeWayComp,
			LessThan, LessThanEqual, GreaterThan, GreaterThanEqual,
			Equals, NotEquals,
			BitAnd, BitXOr, BitOr,
			LogicAnd, LogicOr,
			Assignment,
			AddAssign, SubAssign,
			MultAssign, DivAssign, ModAssign,
			LeftBitAssign, RightBitAssign,
			AndBitAssign, XOrBitAssign, OrBitAssign
		];
	}
}
