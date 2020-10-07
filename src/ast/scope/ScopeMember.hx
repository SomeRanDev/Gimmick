package ast.scope;

import basic.Ref;

import ast.scope.ExpressionMember;
import ast.scope.members.VariableMember;
import ast.scope.members.FunctionMember;
import ast.scope.members.NamespaceMember;

import ast.typing.Type;
import ast.typing.ClassType;

import parsers.expr.PrefixOperator;
import parsers.expr.SuffixOperator;
import parsers.expr.InfixOperator;

enum ScopeMember {
	Include(path: String, brackets: Bool);
	Namespace(namespace: Ref<NamespaceMember>);
	Variable(variable: Ref<VariableMember>);
	Function(func: Ref<FunctionMember>);
	Class(cls: Ref<ClassType>);
	PrefixOperator(op: PrefixOperator, func: Ref<FunctionMember>);
	SuffixOperator(op: SuffixOperator, func: Ref<FunctionMember>);
	InfixOperator(op: InfixOperator, func: Ref<FunctionMember>);
	Expression(expr: ExpressionMember);
}

class ScopeMemberHelper {
	public static function getType(member: ScopeMember): Null<Type> {
		switch(member) {
			case Variable(variable): {
				return variable.get().type;
			}
			case Function(func): {
				return func.get().type.get().returnType;
			}
			case Namespace(namespace): {
				return Type.Namespace(namespace);
			}
			default: {}
		}
		return null;
	}

	public static function find(member: ScopeMember, name: String): Null<Type> {
		switch(member) {
			case Namespace(namespace): {
				final result = namespace.get().members.find(name);
				if(result != null) {
					return getType(result);
				}
			}
			default: {}
		}
		return null;
	}
}
