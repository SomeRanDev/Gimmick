package transpiler;

using haxe.EnumTools;

import parsers.modules.Module;

import ast.scope.ScopeMember;
import ast.scope.ScopeMemberCollection;

import transpiler.Language;
import transpiler.TranspilerContext;
import transpiler.modules.*;

class Transpiler {
	public var headerFile(default, null): OutputHeaderFile;
	public var sourceFile(default, null): OutputSourceFile;
	public var language(default, null): Language;
	public var context(default, null): TranspilerContext;

	var members: ScopeMemberCollection;

	var lastTranspileMemberIndex: Int;

	public function new(members: ScopeMemberCollection, headerFile: OutputHeaderFile, sourceFile: OutputSourceFile, language: Language, context: Null<TranspilerContext> = null) {
		this.members = members;
		this.headerFile = headerFile;
		this.sourceFile = sourceFile;
		this.language = language;
		this.context = context == null ? new TranspilerContext(language) : context;
		lastTranspileMemberIndex = -1;
	}

	public function setInitialMemberIndex(index: Int) {
		lastTranspileMemberIndex = index;
	}

	public function finalMemberIndex(): Int {
		return lastTranspileMemberIndex;
	}

	public static function extend(members: ScopeMemberCollection, transpiler: Transpiler): Transpiler {
		return new Transpiler(members, transpiler.headerFile, transpiler.sourceFile, transpiler.language, transpiler.context);
	}

	public function transpile() {
		for(mem in members) {
			transpileMember(mem);
		}
	}

	function transpileMember(member: ScopeMember) {
		final newIndex = member.getIndex();
		if(lastTranspileMemberIndex != newIndex || alwaysCreateNewLine(newIndex)) {
			lastTranspileMemberIndex = newIndex;
			addSourceAndHeaderContent("");
		}

		switch(member) {
			case Include(path, brackets): {
				TranspileModule_Include.transpile(path, brackets, this);
			}
			case Namespace(namespace): {
				TranspileModule_Namespace.transpile(namespace, this);
			}
			case Variable(variable): {
				TranspileModule_Variable.transpile(variable, this);
			}
			case Function(func): {
				TranspileModule_Function.transpile(func, this);
			}
			case Expression(expr): {
				TranspileModule_Expression.transpile(expr, this);
			}
			default: {}
		}
	}

	function alwaysCreateNewLine(index: Int): Bool {
		return index == 3;
	}

	public function addHeaderContent(content: String) {
		headerFile.addContent(content + "\n");
	}

	public function addSourceContent(content: String) {
		sourceFile.addContent(content + "\n");
	}

	public function addSourceAndHeaderContent(content: String) {
		if(content != "" || !sourceFile.hasTwoPreviousNewlines()) {
			addSourceContent(content);
		}
		if(content != "" || !headerFile.hasTwoPreviousNewlines()) {
			addHeaderContent(content);
		}
	}
}
