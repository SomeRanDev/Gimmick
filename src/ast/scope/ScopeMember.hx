package ast.scope;

import basic.Ref;

using ast.scope.ExpressionMember;
import ast.scope.members.VariableMember;
import ast.scope.members.FunctionMember;
import ast.scope.members.NamespaceMember;
import ast.scope.members.GetSetMember;
import ast.scope.members.AttributeMember;
import ast.scope.members.ModifyMember;
import ast.scope.members.ClassMember;

import ast.typing.Type;
import ast.typing.AttributeArgument.AttributeArgumentValue;

import interpreter.ExpressionInterpreter;
import interpreter.RuntimeScope;
using interpreter.Variant;

import parsers.Parser;
import parsers.expr.PrefixOperator;
import parsers.expr.SuffixOperator;
import parsers.expr.InfixOperator;
import parsers.expr.CallOperator;
import parsers.expr.Position;

import transpiler.TranspilerContext;

enum ScopeMemberType {
	Include(path: String, brackets: Bool, header: Bool);
	Namespace(namespace: Ref<NamespaceMember>);
	Variable(variable: Ref<VariableMember>);
	Function(func: Ref<FunctionMember>);
	GetSet(getset: Ref<GetSetMember>);
	Modify(modify: ModifyMember);
	Class(cls: Ref<ClassMember>);
	PrefixOperator(op: PrefixOperator, func: Ref<FunctionMember>);
	SuffixOperator(op: SuffixOperator, func: Ref<FunctionMember>);
	InfixOperator(op: InfixOperator, func: Ref<FunctionMember>);
	CallOperator(op: CallOperator, func: Ref<FunctionMember>);
	Expression(expr: ExpressionMember);
	Attribute(attr: AttributeMember);
	CompilerAttribute(attr: AttributeMember, params: Null<Array<AttributeArgumentValue>>, position: Position);
}

class ScopeMemberAttribute {
	public var instanceOf(default, null): AttributeMember;
	public var parameters(default, null): Null<Array<AttributeArgumentValue>>;

	public function new(instanceOf: AttributeMember, parameters: Null<Array<AttributeArgumentValue>>) {
		this.instanceOf = instanceOf;
		this.parameters = parameters;
	}

	public function onMemberUsed(parser: Parser) {
		if(instanceOf.name == "cppRequireInclude" && parameters != null) {
			if(parameters.length > 0) {
				switch(parameters[0]) {
					case Raw(str): {
						final brackets = if(parameters.length > 1) {
							switch(parameters[1]) {
								case Value(expr, _): ExpressionInterpreter.interpret(expr, new RuntimeScope());
								default: null;
							}
						} else null;
						parser.requireInclude(str, false, brackets == null ? false : brackets.toBool());
					}
					default: {}
				}
			}
			
		}
	}
}

class ScopeMember {
	public var type(default, null): ScopeMemberType;
	public var attributes(default, null): Array<ScopeMemberAttribute>;

	public function new(type: ScopeMemberType) {
		this.type = type;
		attributes = [];
	}

	public function onMemberUsed(parser: Parser) {
		for(attr in attributes) {
			attr.onMemberUsed(parser);
		}
	}

	public function setAttributes(attributes: Array<ScopeMemberAttribute>) {
		this.attributes = attributes;
	}

	public function addAttributeInstance(instanceOf: AttributeMember, params: Null<Array<AttributeArgumentValue>>) {
		attributes.push(new ScopeMemberAttribute(instanceOf, params));
	}

	public function shouldTranspile(context: TranspilerContext, prevTranspiled: Bool): Bool {
		for(a in attributes) {
			if(a.instanceOf.name == "elseif" && prevTranspiled) {
				return false;
			}
			if(a.instanceOf.name == "else") {
				return !prevTranspiled;
			}
			if(a.instanceOf.name == "if" || a.instanceOf.name == "elseif") {
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

	public function hasAttribute(name: String) {
		for(a in attributes) {
			if(a.instanceOf.name == name) {
				return true;
			}
		}
		return false;
	}

	public function isGlobal(): Bool {
		return hasAttribute("global");
	}

	public function isUntyped(): Bool {
		return hasAttribute("untyped");
	}

	public function getClassSection(context: TranspilerContext): Null<String> {
		for(a in attributes) {
			if(a.instanceOf.name == "classSection") {
				if(a.parameters != null && a.parameters.length > 0) {
					final param = a.parameters[0];
					switch(param) {
						case Value(expr, _): {
							final name = ExpressionInterpreter.interpret(expr, RuntimeScope.fromMap(context.getValues()));
							if(name != null) {
								return name.toString();
							}
						}
						default: {}
					}
				}
			}
		}
		return null;
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
			case Class(cls): {
				return Type.Class(cls.get().type, null);
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

	public function setName(name: String, scope: Scope) {
		@:privateAccess switch(type) {
			case Function(func): {
				func.get().name = name;
			}
			case GetSet(getset): {
				getset.get().setName(name, scope);
			}
			default: {}
		}
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

	public function toFunction(): Null<FunctionMember> {
		return switch(type) {
			case Function(func): func.get();
			default: null;
		}
	}

	public function toAttribute(): AttributeMember {
		switch(type) {
			case Attribute(attr): return attr;
			default: throw "Not an attribute!!";
		}
	}

	public function extractVariableMember(): Null<VariableMember> {
		return switch(type) {
			case Variable(variable): variable.get();
			default: null;
		}
	}

	public function extractFunctionMember(): Null<FunctionMember> {
		return switch(type) {
			case Function(func): func.get();
			default: null;
		}
	}

	public function extractGetSetMember(): Null<GetSetMember> {
		return switch(type) {
			case GetSet(getset): getset.get();
			default: null;
		}
	}

	public function shouldTriggerAutomaticInclude(): Bool {
		switch(type) {
			case Function(func): {
				return !func.get().isInject();
			}
			case GetSet(getset): {
				final getFunc = getset.get().get;
				final setFunc = getset.get().set;
				if(getFunc != null && !getFunc.isInject()) return true;
				return setFunc != null && !setFunc.isInject();
			}
			default: {}
		}
		return true;
	}
}
