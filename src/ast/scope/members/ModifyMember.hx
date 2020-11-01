package ast.scope.members;

import ast.scope.ScopeMember;
import ast.scope.ScopeMemberCollection;
import ast.typing.Type;

import parsers.expr.Position;

class ModifyMember {
	public var type(default, null): Type;
	public var position(default, null): Position;

	public var members(default, null): Null<Map<String,ScopeMember>>;

	public function new(type: Type, position: Position) {
		this.type = type;
		this.position = position;
	}

	public function setAllMembers(members: ScopeMemberCollection, scope: Scope) {
		final clsRef = type.isClassType();
		if(clsRef != null) {
			this.members = null;
			clsRef.get().members.merge(members.members);
		} else {
			this.members = [];
			final prefix = ~/[^_a-zA-Z0-9]/g.replace(type.toString(), "_");
			for(mem in members) {
				final name = switch(mem.type) {
					case ScopeMemberType.Function(func): {
						func.get().type.get().prependArgument("self", type);
						func.get().type.get().setStaticExtension();
						func.get().name;
					}
					case ScopeMemberType.GetSet(getset): {
						getset.get().prependArgument("self", type);
						getset.get().setStaticExtension();
						getset.get().name;
					}
					default: {
						throw "Expected Function or GetSet.";
					}
				}
				scope.file.onTypeUsed(type, true);
				final newName = prefix + "_" + name;
				mem.setName(newName, scope);
				this.members.set(name, mem);
			}
		}
	}

	public function find(name: String): Null<ScopeMember> {
		if(members == null) return null;
		return members.get(name);
	}

	function findFuncByName(funcName: String): Null<FunctionMember> {
		if(members != null) {
			for(m in members) {
				switch(m.type) {
					case Function(func): {
						if(func.get().name == funcName) {
							return func.get();
						}
					}
					default: {}
				}
			}
		}
		return null;
	}
}