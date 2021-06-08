package ast.scope;

import ast.scope.ScopeMember;

import ast.typing.FunctionType.FunctionTypePassResult;

import parsers.error.Error;
import parsers.error.ErrorType;

class ScopeParameterSearchResult {
	public var found(default, null): Bool;
	public var foundMembers(default, null): Null<Array<ScopeMember>>;
	public var error(default, null): Null<FunctionTypePassResult>;
	public var errorMember(default, null): Null<ScopeMember>;

	static var emptyResult: Null<ScopeParameterSearchResult>;

	public function new() {
		found = false;
		foundMembers = null;
		error = null;
		errorMember = null;
	}

	public static function fromEmpty(): ScopeParameterSearchResult {
		if(emptyResult == null) {
			emptyResult = new ScopeParameterSearchResult();
		}
		return emptyResult;
	}

	public static function fromList(members: Array<ScopeMember>) {
		final result = new ScopeParameterSearchResult();
		result.found = true;
		result.foundMembers = members;
		return result;
	}

	public static function fromError(error: Null<FunctionTypePassResult>, errorMember: Null<ScopeMember> = null) {
		final result = new ScopeParameterSearchResult();
		result.error = error;
		result.errorMember = errorMember;
		return result;
	}
}