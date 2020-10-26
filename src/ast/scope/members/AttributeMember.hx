package ast.scope.members;

import ast.scope.ScopeMember;
import ast.scope.ScopeMemberCollection;

import ast.typing.AttributeArgument;
import ast.typing.AttributeArgument.AttributeArgumentValue;

import interpreter.ExpressionInterpreter;
import interpreter.ScopeInterpreter;
import interpreter.RuntimeScope;
using interpreter.Variant;

import transpiler.TranspilerContext;

class AttributeMember {
	public var name(default, null): String;
	public var params(default, null): Null<Array<AttributeArgument>>;
	public var compiler(default, null): Bool;

	public var members(default, null): Null<Array<ScopeMember>>;

	public function new(name: String, params: Null<Array<AttributeArgument>>, compiler: Bool) {
		this.name = name;
		this.params = params;
		this.compiler = compiler;
	}

	public function setAllMembers(members: ScopeMemberCollection) {
		this.members = members.members;
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

	public function toCpp(instanceParams: Null<Array<AttributeArgumentValue>>, context: TranspilerContext): Null<String> {
		return interpretFunctionExpectingString("toCpp", instanceParams, context);
	}

	public function toJs(instanceParams: Null<Array<AttributeArgumentValue>>, context: TranspilerContext): Null<String> {
		return interpretFunctionExpectingString("toJs", instanceParams, context);
	}

	public function interpretFunctionExpectingString(name: String, instanceParams: Null<Array<AttributeArgumentValue>>, context: TranspilerContext): Null<String> {
		final func = findFuncByName(name);
		if(func != null) {
			final scope = new RuntimeScope();
			if(params != null && instanceParams != null) {
				var index = 0;
				for(p in params) {
					final variant = switch(instanceParams[index]) {
						case Raw(str): Str(str);
						case Value(expr, type): {
							ExpressionInterpreter.interpret(expr, RuntimeScope.fromMap(context.getValues()));
						}
						default: null;
					}
					if(variant != null) {
						scope.add(p.name, variant);
					}
					index++;
				}
			}
			final result = ScopeInterpreter.interpret(func.members, scope);
			if(result != null) {
				final value = result.returnValue;
				if(value != null && value.isString()) {
					return value.toString();
				}
			}
		}
		return null;
	}
}
