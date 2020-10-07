package transpiler;

import parsers.modules.Module;

import ast.scope.ScopeMember;
import ast.scope.ScopeMemberCollection;

import transpiler.modules.*;

class Transpiler {
	var members: ScopeMemberCollection;

	var headerFile: OutputHeaderFile;
	var sourceFile: OutputSourceFile;

	public function new(members: ScopeMemberCollection, headerFile: OutputHeaderFile, sourceFile: OutputSourceFile) {
		this.members = members;
		this.headerFile = headerFile;
		this.sourceFile = sourceFile;
	}

	public static function extend(members: ScopeMemberCollection, transpiler: Transpiler): Transpiler {
		return new Transpiler(members, transpiler.headerFile, transpiler.sourceFile);
	}

	public function transpile() {
		for(mem in members) {
			transpileMember(mem);
		}
	}

	function transpileMember(member: ScopeMember) {
		switch(member) {
			case Include(path, brackets): {
				sourceFile.addContent(TranspileModule_Include.transpile(path, brackets));
			}
			case Namespace(namespace): {
				TranspileModule_Namespace.transpile(namespace, this);
			}
			case Variable(variable): {
				sourceFile.addContent(TranspileModule_Variable.transpile(variable));
			}
			case Function(func): {
				sourceFile.addContent(TranspileModule_Function.transpile(func));
			}
			case Expression(expr): {
				sourceFile.addContent(TranspileModule_Expression.transpile(expr));
			}
			default: {}
		}
	}
}
