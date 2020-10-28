package transpiler.modules;

import ast.scope.members.AttributeMember;

import ast.typing.AttributeArgument.AttributeArgumentValue;

import parsers.expr.Position;

class TranspileModule_CompilerAttribute {
	public static function transpile(attr: AttributeMember, params: Null<Array<AttributeArgumentValue>>, position: Position, transpiler: Transpiler): Bool {
		if(transpiler.context.isCpp()) {
			final cppContent = attr.toCpp(params, position, transpiler.context);
			if(cppContent != null) {
				transpiler.addSourceContent(cppContent);
				return true;
			}
		} else if(transpiler.context.isJs()) {
			final jsContent = attr.toJs(params, position, transpiler.context);
			if(jsContent != null) {
				transpiler.addSourceContent(jsContent);
				return true;
			}
		}
		return false;
	}
}
