package parsers.modules;

import basic.Ref;

import ast.typing.Type;
import ast.scope.ExpressionMember;
import ast.scope.members.VariableMember;
import ast.scope.members.FunctionMember;

import parsers.expr.Expression;

enum Module {
	Variable(variable: VariableMember);
	Function(func: FunctionMember);
	Import(path: String, mainFunction: Null<Ref<FunctionMember>>);
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
