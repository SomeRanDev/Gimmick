package parsers.expr;

import parsers.Parser;
using parsers.expr.Expression;
using parsers.expr.TypedExpression;

enum QuantumExpressionInternal {
	Untyped(e: Expression);
	Typed(e: TypedExpression);
}

abstract QuantumExpression(QuantumExpressionInternal) from QuantumExpressionInternal to QuantumExpressionInternal {
	inline function new(i: QuantumExpressionInternal) {
		this = i;
	}

	@:from
	public static function fromUntyped(_untyped: Null<Expression>): Null<QuantumExpression> {
		if(_untyped == null) return null;
		return new QuantumExpression(Untyped(_untyped));
	}

	@:from
	public static function fromTyped(_typed: Null<TypedExpression>): Null<QuantumExpression> {
		if(_typed == null) return null;
		return new QuantumExpression(Typed(_typed));
	}

	public function typeExpression(parser: Parser): Null<QuantumExpression> {
		return switch(this) {
			case Untyped(e): {
				final typed = e.getType(parser, false);
				if(typed != null) {
					fromTyped(typed);
				} else {
					null;
				}
			}
			case Typed(e): e;
		}
	}

	public function getPosition(): Position {
		return switch(this) {
			case Untyped(e): e.getPosition();
			case Typed(e): e.getPosition();
		}
	}
}
