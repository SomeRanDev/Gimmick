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

	public function new() {
		members = [];
	}

	public function add(member: ScopeMember) {
		members.push(member);
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
			return true;
		}
		return false;
	}

	public function find(name: String): Null<ScopeMember> {
		for(member in members) {
			switch(member.type) {
				case Variable(variable): {
					if(variable.get().name == name) {
						return member;
					}
				}
				case Function(func): {
					if(func.get().name == name) {
						return member;
					}
				}
				case GetSet(getset): {
					if(getset.get().name == name) {
						return member;
					}
				}
				case Namespace(namespace): {
					if(namespace.get().name == name) {
						return member;
					}
				}
				default: {}
			}
		}
		return null;
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
}
