package parsers.expr;

import ast.typing.Type;

using ast.scope.ScopeMember;

using ast.typing.NumberType;

import parsers.error.Error;

import parsers.expr.Expression;
import parsers.expr.Expression.ExpressionHelper;
import parsers.expr.Operator;
import parsers.expr.Position;

class InfixOperator extends Operator {
	public override function operatorType(): String {
		return "infix";
	}

	public override function requiredArgumentLength(): Int {
		return 1;
	}

	public function findReturnType(ltype: Type, rtype: Type, position: Position): Null<Type> {
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

		final overloadOp = ltype.findOverloadedInfixOperator(this, rtype);
		if(overloadOp != null) {
			switch(overloadOp.type) {
				case ScopeMemberType.InfixOperator(_, func): {
					return func.get().type.get().returnType;
				}
				default: {}
			}
		}

		if(op == "=") {
			return ltype.canBeAssigned(rtype) == null ? ltype : null;
		}

		if((op == "==" || op == "!=") && ltype.baseTypesEqual(rtype)) {
			return ltype;
		}

		{
			final lnumType = ltype.isNumber();
			final rnumType = rtype.isNumber();
			if(lnumType != null && rnumType != null) {
				if(lnumType.isWholeNumberType() && rnumType.isWholeNumberType() ? isWholeNumberOperator() : isNumericOperator()) {
					return lnumType.priority() > rnumType.priority() ? ltype : rtype;
				}
			}
		}

		if(ltype.bothSameAndNotNull(rtype)) {
			final defaultsTest = switch(ltype.type) {
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

	public function isNumericOperator(): Bool {
		return op == "+" || op == "-" || op == "*" || op == "/";
	}

	public function isWholeNumberOperator(): Bool {
		return isNumericOperator() || op == "%" || op == "&" || op == "^" || op == "|";
	}

	public function isGenericInput(): Bool {
		return op == "!";
	}
}

class InfixOperators {
	public static var GenericInput = new InfixOperator("!", 0xff00, "genericInput", ToFunction);

	public static var DotAccess = new InfixOperator(".", 0xf000, "dotAccess", ToAccessFunction);
	public static var ArrowAccess = new InfixOperator("->", 0xf000, "pointerAccess", ToAccessFunction);
	public static var StaticAccess = new InfixOperator("::", 0xf000, "staticAccess", ToAccessFunction);

	public static var Multiply = new InfixOperator("*", 0xd000, "multiply", CppOperatorOverload);
	public static var Divide = new InfixOperator("/", 0xd000, "divide", CppOperatorOverload);
	public static var Mod = new InfixOperator("%", 0xd000, "modulus", CppOperatorOverload);

	public static var Add = new InfixOperator("+", 0xc000, "add", CppOperatorOverload);
	public static var Subtract = new InfixOperator("-", 0xc000, "subtract", CppOperatorOverload);

	public static var BitLeft = new InfixOperator("<<", 0xb000, "shiftLeft", CppOperatorOverload);
	public static var BitRight = new InfixOperator(">>", 0xb000, "shiftRight", CppOperatorOverload);

	public static var ThreeWayComp = new InfixOperator("<=>", 0xa000, "spaceship", CppOperatorOverload);

	public static var LessThan = new InfixOperator("<", 0x9000, "lessThen", CppOperatorOverload);
	public static var LessThanEqual = new InfixOperator("<=", 0x9000, "lessThanOrEqual", CppOperatorOverload);
	public static var GreaterThan = new InfixOperator(">", 0x9000, "greaterThan", CppOperatorOverload);
	public static var GreaterThanEqual = new InfixOperator(">=", 0x9000, "greaterThanOrEqual", CppOperatorOverload);

	public static var Equals = new InfixOperator("==", 0x8000, "equals", CppOperatorOverload);
	public static var NotEquals = new InfixOperator("!=", 0x8000, "notEquals", CppOperatorOverload);

	public static var BitAnd = new InfixOperator("&", 0x7000, "bitAnd", CppOperatorOverload);
	public static var BitXOr = new InfixOperator("^", 0x6000, "bitXOr", CppOperatorOverload);
	public static var BitOr = new InfixOperator("|", 0x5000, "bitOr", CppOperatorOverload);

	public static var NullCoalesce = new InfixOperator("??", 0x4000, "nullOr", CppOperatorOverload);

	public static var LogicAnd = new InfixOperator("&&", 0x3000, "logicAnd", CppOperatorOverload);
	public static var LogicOr = new InfixOperator("||", 0x2000, "logicOr", CppOperatorOverload);

	public static var Assignment = new InfixOperator("=", 0x1000, "assign", CppOperatorOverload);
	public static var AddAssign = new InfixOperator("+=", 0x1000, "addAssign", CppOperatorOverload);
	public static var SubAssign = new InfixOperator("-=", 0x1000, "subtractAssign", CppOperatorOverload);
	public static var MultAssign = new InfixOperator("*=", 0x1000, "multiplyAssign", CppOperatorOverload);
	public static var DivAssign = new InfixOperator("/=", 0x1000, "divideAssign", CppOperatorOverload);
	public static var ModAssign = new InfixOperator("%=", 0x1000, "modulusAssign", CppOperatorOverload);
	public static var LeftBitAssign = new InfixOperator("<<=", 0x1000, "shiftLeftAssign", CppOperatorOverload);
	public static var RightBitAssign = new InfixOperator(">>=", 0x1000, "shiftRightAssign", CppOperatorOverload);
	public static var AndBitAssign = new InfixOperator("&=", 0x1000, "bitAndAssign", CppOperatorOverload);
	public static var XOrBitAssign = new InfixOperator("^=", 0x1000, "bitXOrAssign", CppOperatorOverload);
	public static var OrBitAssign = new InfixOperator("|=", 0x1000, "bitOrAssign", CppOperatorOverload);

	public static function all(): Array<InfixOperator> {
		return [
			DotAccess, ArrowAccess, StaticAccess,
			GenericInput,
			Multiply, Divide, Mod,
			Add, Subtract,
			BitLeft, BitRight,
			ThreeWayComp,
			LessThan, LessThanEqual, GreaterThan, GreaterThanEqual,
			Equals, NotEquals,
			BitAnd, BitXOr, BitOr,
			NullCoalesce,
			LogicAnd, LogicOr,
			Assignment,
			AddAssign, SubAssign,
			MultAssign, DivAssign, ModAssign,
			LeftBitAssign, RightBitAssign,
			AndBitAssign, XOrBitAssign, OrBitAssign
		];
	}
}
