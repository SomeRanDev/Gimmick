package ast.scope.members;

import ast.typing.AttributeArgument;

class AttributeMember {
	public var name(default, null): String;
	public var params(default, null): Null<Array<AttributeArgument>>;
	public var compiler(default, null): Bool;

	public function new(name: String, params: Null<Array<AttributeArgument>>, compiler: Bool) {
		this.name = name;
		this.params = params;
		this.compiler = compiler;
	}
}
