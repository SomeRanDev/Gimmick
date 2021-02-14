package ast.typing;

import ast.typing.Type;
import ast.typing.FunctionType;
import ast.typing.TemplateType;
import ast.typing.TemplateArgumentRequirement;

import parsers.expr.Position;

class TemplateArgument {
	public var name: String;
	public var type: TemplateType;
	public var position: Position;
	public var defaultType: Null<Type>;

	public function new(name: String, restrictions: Null<Array<TemplateArgumentRequirement>>, position: Position, defaultType: Null<Type> = null) {
		this.name = name;
		this.type = new TemplateType("", restrictions);
		this.position = position;
		this.defaultType = defaultType;
	}
}
