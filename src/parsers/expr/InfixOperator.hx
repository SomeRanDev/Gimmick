package parsers.expr;

import parsers.expr.Expression;
import parsers.expr.Expression.ExpressionHelper;
import parsers.expr.Operator;

class InfixOperator extends Operator {
	public function toCpp(lexpr: Expression, rexpr: Expression) {
		return ExpressionHelper.toCpp(lexpr) + " " + op + " " + ExpressionHelper.toCpp(rexpr);
	}
}

class InfixOperators {
	static var DotAccess = new InfixOperator(".", 0xf000);
	static var ArrowAccess = new InfixOperator("->", 0xf000);

	static var Multiply = new InfixOperator("*", 0xd000);
	static var Divide = new InfixOperator("/", 0xd000);
	static var Mod = new InfixOperator("%", 0xd000);

	static var Add = new InfixOperator("+", 0xc000);
	static var Subtract = new InfixOperator("-", 0xc000);

	static var BitLeft = new InfixOperator("<<", 0xb000);
	static var BitRight = new InfixOperator(">>", 0xb000);

	static var ThreeWayComp = new InfixOperator("<=>", 0xa000);

	static var LessThan = new InfixOperator("<", 0x9000);
	static var LessThanEqual = new InfixOperator("<=", 0x9000);
	static var GreaterThan = new InfixOperator(">", 0x9000);
	static var GreaterThanEqual = new InfixOperator(">=", 0x9000);

	static var Equals = new InfixOperator("==", 0x8000);
	static var NotEquals = new InfixOperator("!=", 0x8000);

	static var BitAnd = new InfixOperator("&", 0x7000);
	static var BitXOr = new InfixOperator("^", 0x6000);
	static var BitOr = new InfixOperator("|", 0x5000);

	static var LogicAnd = new InfixOperator("&&", 0x4000);
	static var LogicOr = new InfixOperator("||", 0x3000);

	static var Assignment = new InfixOperator("=", 0x2000);
	static var AddAssign = new InfixOperator("+=", 0x2000);
	static var SubAssign = new InfixOperator("-=", 0x2000);
	static var MultAssign = new InfixOperator("*=", 0x2000);
	static var DivAssign = new InfixOperator("/=", 0x2000);
	static var ModAssign = new InfixOperator("%=", 0x2000);
	static var LeftBitAssign = new InfixOperator("<<=", 0x2000);
	static var RightBitAssign = new InfixOperator(">>=", 0x2000);
	static var AndBitAssign = new InfixOperator("&=", 0x2000);
	static var XOrBitAssign = new InfixOperator("^=", 0x2000);
	static var OrBitAssign = new InfixOperator("|=", 0x2000);

	public static function all(): Array<InfixOperator> {
		return [
			DotAccess, ArrowAccess,
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
