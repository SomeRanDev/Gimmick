package ast.scope;

import basic.Ref;

import ast.scope.ScopeMember;
import ast.typing.Type;
import ast.typing.ClassType;

import ast.scope.members.FunctionMember;

import parsers.expr.PrefixOperator;
import parsers.expr.SuffixOperator;
import parsers.expr.InfixOperator;

class ScopeMemberCollection {
	public var length(get, never): Int;
	public var members(default, null): Array<ScopeMember>;

	var existingNames(default, null): Array<String>;

	public function new() {
		members = [];
		existingNames = [];
	}

	public function add(member: ScopeMember) {
		members.push(member);
		final name = findName(member);
		existingNames.push(name == null ? "" : name);
	}

	public function get_length(): Int {
		return members.length;
	}

	public function iterator() {
		return members.iterator();
	}

	public function at(index: Int): ScopeMember {
		return members[index];
	}

	public function replace(index: Int, scopeMember: ScopeMember): Bool {
		if(index >= 0 && index < members.length) {
			members[index] = scopeMember;
			final name = findName(scopeMember);
			existingNames[index] = name == null ? "" : name;
			return true;
		}
		return false;
	}

	public function merge(newMembers: Array<ScopeMember>) {
		for(mem in newMembers) {
			final newName = findName(mem);
			final existingIndex = newName == null ? -1 : existingNames.indexOf(newName);
			if(existingIndex == -1) {
				members.push(mem);
			} else {
				replace(existingIndex, mem);
			}
		}
	}

	public function find(name: String): Null<ScopeMember> {
		return findIn(name, members);
	}

	public static function findIn(name: String, members: Array<ScopeMember>): Null<ScopeMember> {
		for(member in members) {
			final memName = findName(member);
			if(memName == name) {
				return member;
			}
		}
		return null;
	}

	public static function findName(member: ScopeMember): Null<String> {
		return switch(member.type) {
			case Variable(variable): variable.get().name;
			case Function(func): func.get().name;
			case GetSet(getset): getset.get().name;
			case Namespace(namespace): namespace.get().name;
			default: null;
		}
	}

	public function findClassType(name: String): Null<Ref<ClassType>> {
		for(member in members) {
			switch(member.type) {
				case Class(cls): {
					if(cls.get().name == name) {
						return cls;
					}
				}
				default: {}
			}
		}
		return null;
	}

	public function findPrefixOperator(op: PrefixOperator): Null<Ref<FunctionMember>> {
		for(member in members) {
			switch(member.type) {
				case PrefixOperator(prefix, func): {
					if(prefix.op == op.op) {
						return func;
					}
				}
				default: {}
			}
		}
		return null;
	}

	public function findSuffixOperator(op: SuffixOperator): Null<Ref<FunctionMember>> {
		for(member in members) {
			switch(member.type) {
				case SuffixOperator(suffix, func): {
					if(suffix.op == op.op) {
						return func;
					}
				}
				default: {}
			}
		}
		return null;
	}

	public function findInfixOperator(op: InfixOperator, inputType: Type): Null<Ref<FunctionMember>> {
		for(member in members) {
			switch(member.type) {
				case InfixOperator(suffix, func): {
					if(suffix.op == op.op) {
						final args = func.get().type.get().arguments;
						if(args.length > 0 && args[0].type == inputType) {
							return func;
						}
					}
				}
				default: {}
			}
		}
		return null;
	}

	public function findModify(type: Type, name: String): Null<ScopeMember> {
		for(member in members) {
			switch(member.type) {
				case Modify(modify): {
					if(modify.members != null && modify.type.canBePassed(type) == null) {
						final result = modify.find(name);
						if(result != null) {
							return result;
						}
					}
				}
				default: {}
			}
		}
		return null;
	}
}
