package ast.scope;

import basic.Ref;

using ast.scope.ExpressionMember;
import ast.scope.members.VariableMember;
import ast.scope.members.FunctionMember;
import ast.scope.members.NamespaceMember;
import ast.scope.members.GetSetMember;
import ast.scope.members.AttributeMember;

import ast.typing.Type;
import ast.typing.ClassType;
import ast.typing.AttributeArgument.AttributeArgumentValue;

import ast.scope.members.AttributeMember;

import interpreter.ExpressionInterpreter;
import interpreter.RuntimeScope;
using interpreter.Variant;

import parsers.expr.PrefixOperator;
import parsers.expr.SuffixOperator;
import parsers.expr.InfixOperator;

import transpiler.TranspilerContext;

enum ScopeMemberType {
	Include(path: String, brackets: Bool);
	Namespace(namespace: Ref<NamespaceMember>);
	Variable(variable: Ref<VariableMember>);
	Function(func: Ref<FunctionMember>);
	GetSet(getset: Ref<GetSetMember>);
	Class(cls: Ref<ClassType>);
	PrefixOperator(op: PrefixOperator, func: Ref<FunctionMember>);
	SuffixOperator(op: SuffixOperator, func: Ref<FunctionMember>);
	InfixOperator(op: InfixOperator, func: Ref<FunctionMember>);
	Expression(expr: ExpressionMember);
	Attribute(attr: AttributeMember);
	CompilerAttribute(attr: AttributeMember, params: Null<Array<AttributeArgumentValue>>);
}

class ScopeMemberAttribute {
	public var instanceOf(default, null): AttributeMember;
	public var parameters(default, null): Null<Array<AttributeArgumentValue>>;

	public function new(instanceOf: AttributeMember, parameters: Null<Array<AttributeArgumentValue>>) {
		this.instanceOf = instanceOf;
		this.parameters = parameters;
	}
}

class ScopeMember {
	public var type(default, null): ScopeMemberType;
	public var attributes(default, null): Array<ScopeMemberAttribute>;

	public function new(type: ScopeMemberType) {
		this.type = type;
		attributes = [];
	}

	public function addAttributeInstance(instanceOf: AttributeMember, params: Null<Array<AttributeArgumentValue>>) {
		attributes.push(new ScopeMemberAttribute(instanceOf, params));
	}

	public function shouldTranspile(context: TranspilerContext): Bool {
		for(a in attributes) {
			if(a.instanceOf.name == "if") {
				if(a.parameters != null && a.parameters.length > 0) {
					switch(a.parameters[0]) {
						case Value(expr, type): {
							final result = ExpressionInterpreter.interpret(expr, RuntimeScope.fromMap(context.getValues()));
							if(result != null) {
								return result.toBool();
							}
						}
						default: {}
					}
				}
			}
		}
		return true;
	}

	public function isGlobal(): Bool {
		for(a in attributes) {
			if(a.instanceOf.name == "global") {
				return true;
			}
		}
		return false;
	}

	public function getType(): Null<Type> {
		switch(type) {
			case Variable(variable): {
				return variable.get().type;
			}
			case Function(func): {
				return Type.Function(func.get().type, null);
			}
			case Namespace(namespace): {
				return Type.Namespace(namespace);
			}
			case GetSet(getset): {
				final getFunc = getset.get().get;
				if(getFunc != null) {
					return getFunc.type.get().returnType;
				}
			}
			default: {}
		}
		return null;
	}

	public function find(name: String): Null<Type> {
		switch(type) {
			case Namespace(namespace): {
				final result = namespace.get().members.find(name);
				if(result != null) {
					return result.getType();
				}
			}
			default: {}
		}
		return null;
	}

	public function isPass(): Bool {
		switch(type) {
			case Expression(e): return e.isPass();
			default: return false;
		}
	}

	public function isGetSet(): Bool {
		switch(type) {
			case GetSet(_): return true;
			default: return false;
		}
	}

	public function toAttribute(): AttributeMember {
		switch(type) {
			case Attribute(attr): return attr;
			default: throw "Not an attribute!!";
		}
	}
}
