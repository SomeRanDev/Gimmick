package parsers.modules;

import basic.Ref;

import ast.typing.Type;
import ast.scope.ExpressionMember;
import ast.scope.members.VariableMember;
import ast.scope.members.FunctionMember;
import ast.scope.members.ClassMember;
import ast.scope.members.GetSetMember;
import ast.scope.members.AttributeMember;
import ast.scope.members.ModifyMember;

import ast.typing.AttributeArgument.AttributeArgumentValue;

import parsers.expr.Expression;
import parsers.expr.Position;

enum Module {
	Nothing;
	Variable(variable: VariableMember);
	Function(func: FunctionMember);
	Class(cls: ClassMember);
	GetSet(getset: GetSetMember);
	Modify(modify: ModifyMember);
	Attribute(attribute: AttributeMember);
	AttributeInstance(instanceOf: AttributeMember, params: Null<Array<AttributeArgumentValue>>, position: Position);
	Import(path: String, mainFunction: Null<Ref<FunctionMember>>);
	Include(path: String, header: Bool, brackets: Bool);
	Expression(expr: ExpressionMember);
	NamespaceStart(name: Array<String>);
	NamespaceEnd;
}

class ModuleHelper {
	public static function isExpression(module: Module): Bool {
		switch(module) {
			case Expression(_): return true;
			default:
		}
		return false;
	}
}
