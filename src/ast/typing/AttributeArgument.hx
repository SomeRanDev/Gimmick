package ast.typing;

import ast.typing.Type;

import parsers.expr.Expression;
import parsers.expr.Position;

import interpreter.RuntimeScope;
import interpreter.ExpressionInterpreter;
import interpreter.Variant;
import interpreter.Variant.VariantType;

enum AttributeArgumentType {
	Raw;
	String;
	Number;
	Bool;
	List(type: AttributeArgumentType);
}

enum AttributeArgumentValue {
	Raw(str: String);
	Value(expr: Expression, type: AttributeArgumentType);
	List(exprs: Array<Expression>, type: AttributeArgumentType);
}

class AttributeArgument {
	public var name(default, null): String;
	public var type(default, null): AttributeArgumentType;
	public var optional(default, null): Bool;
	public var expr(default, null): Null<Expression>;
	public var position(default, null): Position;

	public function new(name: String, type: AttributeArgumentType, optional: Bool, position: Position, expr: Null<Expression>) {
		this.name = name;
		this.type = type;
		this.optional = optional;
		this.position = position;
		this.expr = expr;
	}

	public function getType(): Type {
		return switch(type) {
			case Raw | String: Type.String();
			case Number: Type.Number(Int);
			case Bool: Type.Boolean();
			default: Type.Void();
		}
	}

	public function isRequired(): Bool {
		return !optional && expr == null;
	}

	public function getDefaultValue(runtimeScope: RuntimeScope): Null<Variant> {
		if(expr != null) {
			final result = ExpressionInterpreter.interpret(expr, runtimeScope);
			return result;
		}
		if(optional) {
			final variantType: Null<VariantType> = switch(type) {
				case Raw | String: TStr;
				case Number: TNum;
				case Bool: TBool;
				default: null;
			}
			if(variantType != null) {
				return Nullable(null, variantType);
			}
		}
		return null;
	}
}

class AttributeArgumentTypeHelper {
	public static function isRaw(type: AttributeArgumentType): Bool {
		return switch(type) {
			case Raw: true;
			default: false;
		}
	}
}
