package ast.scope;

import ast.scope.ScopeMember;

class GlobalScopeMember {
	public var members(default, null): Array<ScopeMember>;
	public var attributes(default, null): Array<ScopeMember>;
	public var scope(default, null): Scope;

	public function new(members: Array<ScopeMember>, attributes: Array<ScopeMember>, scope: Scope) {
		this.members = members;
		this.attributes = attributes;
		this.scope = scope;
	}
}
