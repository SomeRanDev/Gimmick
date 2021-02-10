package ast.typing;

import ast.typing.Type;
import ast.typing.FunctionType;
import ast.typing.TemplateType;

enum TemplateArgumentRequirement {
	HasVariable(name: String, type: Type);
	HasFunction(name: String, func: FunctionType);
	HasAttribute(name: String);
	Extends(type: Type);
	Matches(template: TemplateType);
}

class TemplateArgument {
	public var name: String;
	public var type: TemplateType;
	public var defaultType: Null<Type>;

	public function new(name: String, restrictions: Null<Array<TemplateArgumentRequirement>>, defaultType: Null<Type> = null) {
		this.name = name;
		this.type = new TemplateType("", restrictions);
		this.defaultType = defaultType;
	}
}
