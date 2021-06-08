package ast.scope;

import basic.Ref;

import ast.scope.ScopeMember;
import ast.scope.ScopeParameterSearchResult;
import ast.scope.members.ClassMember;
import ast.typing.Type;
import ast.typing.ClassType;
import ast.typing.FunctionType;
import ast.typing.FunctionType.FunctionTypePassResult;

import ast.scope.members.FunctionMember;

import parsers.error.Error;
import parsers.error.ErrorType;
import parsers.error.ErrorPromise;
import parsers.expr.Operator;
import parsers.expr.PrefixOperator;
import parsers.expr.SuffixOperator;
import parsers.expr.InfixOperator;
using parsers.expr.TypedExpression;

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

	public function map(callback: (ScopeMember) -> ScopeMember): ScopeMemberCollection {
		final result = new ScopeMemberCollection();
		result.members = members.map(callback);
		result.existingNames = existingNames;
		return result;
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

	public function setAllMembers(members: Array<ScopeMember>) {
		this.members = members;
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

	public function classSort() {
		haxe.ds.ArraySort.sort(members, function(a, b) {
			final getPriority = function(mem: ScopeMember) {
				return switch(mem.type) {
					case Variable(_): 10000;
					case GetSet(_): 20000;
					case Function(func): {
						final t = func.get().type.get();
						if(t.isConstructor()) {
							30000 + (100 * t.arguments.length);
						} else if(t.isDestructor()) {
							40000;
						} else {
							50000 + (100 * t.arguments.length);
						}
					}
					case PrefixOperator(_): 60000;
					case SuffixOperator(_): 70000;
					case InfixOperator(_): 80000;
					default: 99999;
				}
			};
			return getPriority(a) - getPriority(b);
		});
	}

	public function find(name: String): Null<ScopeMember> {
		return findIn(name, members);
	}

	public function findWithParameters(name: String, typeArgs: Null<Array<Type>>, params: Array<TypedExpression>): ScopeParameterSearchResult {
		final options = findAll(name);
		if(options != null) {
			return findWithParametersFromExprOptions(options, typeArgs, params);
		}
		return ScopeParameterSearchResult.fromEmpty();
	}

	public function findConstructorWithParameterExprs(params: Array<TypedExpression>): ScopeParameterSearchResult {
		return findConstructorWithParameters(params.map(p -> p.getType()));
	}

	public function hasConstructors(): Bool {
		final options = findAllConstructors();
		return options != null && options.length > 0;
	}

	public function findConstructorWithParameters(params: Array<Type>): ScopeParameterSearchResult {
		final options = findAllConstructors();
		if(options != null) {
			return findWithParametersFromOptions(options, null, params);
		}
		return ScopeParameterSearchResult.fromEmpty();
	}

	public function findWithParametersFromExprOptions(options: Array<ScopeMember>, typeArgs: Null<Array<Type>>, params: Array<TypedExpression>): ScopeParameterSearchResult {
		return findWithParametersFromOptions(options, typeArgs, params.map(p -> p.getType()));
	}

	public function findWithParametersFromOptions(options: Array<ScopeMember>, typeArgs: Null<Array<Type>>, params: Array<Type>): ScopeParameterSearchResult {
		if(options.length == 0) return ScopeParameterSearchResult.fromEmpty();

		var onlyClass = true;
		var classMember: Null<ClassMember> = null;
		for(member in options) {
			switch(member.type) {
				case Function(_): onlyClass = false;
				case Class(clsMemberRef): {
					if(classMember == null) {
						classMember = clsMemberRef.get();
					}
				}
				default: {}
			}
		}

		if(onlyClass && classMember != null) {
			return classMember.findConstructorWithParameters(params);
		}

		if(options.length == 0) return ScopeParameterSearchResult.fromEmpty();

		var callback: Null<() -> Void> = null;

		var resultingIndex = 0;
		final possibilities = [];
		var errorMember: Null<ScopeMember> = null;
		var errorReason: Null<FunctionTypePassResult> = null;
		for(member in options) {
			switch(member.type) {
				case Function(func): {
					var funcType = func.get().type.get();
					if(typeArgs != null) {
						funcType = funcType.applyTypeArguments(typeArgs);
					}
					final result = funcType.canPassTypes(params);
					//trace(result, funcType, typeArgs, params, typeArgs != null ? funcType.applyTypeArguments(typeArgs) : null);
					if(result != null) {
						if(errorReason == null || (errorReason.error == ErrorType.TooManyFunctionParametersProvided && result.error != ErrorType.TooManyFunctionParametersProvided)) {
							errorMember = member;
							errorReason = result;
						}
					} else {
						possibilities.push(member);
					}
				}
				default: {
					return ScopeParameterSearchResult.fromEmpty();
				}
			}
		}
		if(possibilities.length == 0) {
			if(errorReason != null) {
				//Error.addErrorPromise("funcWrongParam", errorReason);
			}
			if(errorMember != null) {
				return ScopeParameterSearchResult.fromError(errorReason, errorMember);
			}
			return ScopeParameterSearchResult.fromEmpty();
		}
		return ScopeParameterSearchResult.fromList(possibilities);
	}

	public function findAll(name: String): Null<Array<ScopeMember>> {
		var result: Null<Array<ScopeMember>> = null;
		for(member in members) {
			final memName = findName(member);
			if(memName == name) {
				if(result == null) result = [];
				result.push(member);
			}
		}
		return result;
	}

	public function findAllConstructors(): Null<Array<ScopeMember>> {
		var result: Null<Array<ScopeMember>> = null;
		for(member in members) {
			switch(member.type) {
				case Function(func): {
					if(func.get().isConstructor()) {
						if(result == null) {
							result = [];
						}
						result.push(member);
					}
				}
				default: {}
			}
		}
		return result;
	}

	public function findAllOperators(op: Operator): Null<Array<ScopeMember>> {
		var result: Array<ScopeMember> = [];
		for(member in members) {
			switch(member.type) {
				case ScopeMemberType.PrefixOperator(otherOp, _): if(otherOp.op == op.op) result.push(member);
				case ScopeMemberType.InfixOperator(otherOp, _): if(otherOp.op == op.op) result.push(member);
				case ScopeMemberType.SuffixOperator(otherOp, _): if(otherOp.op == op.op) result.push(member);
				case ScopeMemberType.CallOperator(otherOp, _): if(otherOp.op == op.op) result.push(member);
				default: {}
			}
		}
		return result.length == 0 ? null : result;
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
			case Class(cls): cls.get().name;
			default: null;
		}
	}

	public function hasVariableType(name: String, type: Type): Bool {
		final options = findAll(name);
		if(options != null) {
			for(o in options) {
				switch(o.type) {
					case Variable(variable): {
						if(variable.get().type.equals(type)) {
							return true;
						}
					}
					default: {}
				}
			}
		}
		return false;
	}

	public function hasFunctionType(name: String, funcType: FunctionType): Bool {
		final options = findAll(name);
		if(options != null) {
			return findWithParametersFromOptions(options, null, funcType.arguments.map(a -> a.type)).found;
		}
		return false;
	}

	public function findClassType(name: String): Null<Type> {
		for(member in members) {
			switch(member.type) {
				case Class(cls): {
					if(cls.get().name == name) {
						return Type.Class(cls.get().type, null);
					}
				}
				case TemplateType(index, arg): {
					if(arg.get().name == name) {
						return Type.Template(name);
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
		final temp = findAllModify(type, name);
		if(temp != null && temp.length > 0) {
			return temp[0];
		}
		return null;
	}

	public function findAllModify(type: Type, name: String): Null<Array<ScopeMember>> {
		var result: Null<Array<ScopeMember>> = null;
		for(member in members) {
			switch(member.type) {
				case Modify(modify): {
					if(modify.members != null && modify.type.canBePassed(type) == null) {
						final mem = modify.find(name);
						if(mem != null) {
							if(result == null) {
								result = [];
							}
							result.push(mem);
						}
					}
				}
				default: {}
			}
		}
		return result;
	}

	public function findAllModifyWithParameters(type: Type, name: String, params: Array<TypedExpression>): ScopeParameterSearchResult {
		final options = findAllModify(type, name);
		if(options != null) {
			return findWithParametersFromExprOptions(options, null, params);
		}
		return ScopeParameterSearchResult.fromEmpty();
	}
}
