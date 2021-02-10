package ast.typing;

import ast.typing.TemplateArgument.TemplateArgumentRequirement;

class TemplateType {
	public var name: String;
	public var restrictions: Null<Array<TemplateArgumentRequirement>>;

	public function new(name: String, restrictions: Null<Array<TemplateArgumentRequirement>>) {
		this.name = name;
		this.restrictions = restrictions;
	}
}
