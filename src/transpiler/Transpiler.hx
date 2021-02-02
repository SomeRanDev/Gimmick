package transpiler;

using haxe.EnumTools;

import haxe.ds.GenericStack;

import parsers.modules.Module;

import ast.scope.ScopeMember;
import ast.scope.ScopeMemberCollection;

import transpiler.Language;
import transpiler.TranspilerContext;
import transpiler.modules.*;
import transpiler.modules.TranspileModule_Modify;

class Transpiler {
	public var headerFile(default, null): OutputFileContent;
	public var sourceFile(default, null): OutputFileContent;
	public var language(default, null): Language;
	public var context(default, null): TranspilerContext;

	public var transpileCount(default, null): Int;

	var members: ScopeMemberCollection;

	var lastTranspileMemberIndex: Int;

	public function new(members: ScopeMemberCollection, headerFile: OutputFileContent, sourceFile: OutputFileContent, language: Language, context: Null<TranspilerContext> = null) {
		this.members = members;
		this.headerFile = headerFile;
		this.sourceFile = sourceFile;
		this.language = language;
		this.context = context == null ? new TranspilerContext(language) : context;
		transpileCount = 0;
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
		transpileAll(members.members, context);
	}

	public function transpileAll(members: Array<ScopeMember>, context: TranspilerContext) {
		var prevCond = true;
		for(mem in members) {
			if(mem.shouldTranspile(context, prevCond)) {
				prevCond = true;
				if(transpileMember(mem)) {
					transpileCount++;
				}
			} else {
				prevCond = false;
			}
		}
	}

	public function transpileMember(member: ScopeMember): Bool {
		final newIndex = member.type.getIndex();
		if(lastTranspileMemberIndex != newIndex || alwaysCreateNewLine(newIndex)) {
			lastTranspileMemberIndex = newIndex;
			addSourceAndHeaderContent("");
		}

		switch(member.type) {
			case Include(path, brackets, header): {
				TranspileModule_Include.transpile(path, brackets, header, this);
				return false;
			}
			case Namespace(namespace): {
				TranspileModule_Namespace.transpile(namespace, this);
			}
			case Variable(variable): {
				TranspileModule_Variable.transpile(variable, this);
			}
			case Function(func): {
				TranspileModule_Function.transpile(func.get(), this);
				return func.get().shouldTranspile();
			}
			case GetSet(getset): {
				final gs = getset.get();
				if(gs.get != null) {
					TranspileModule_Function.transpile(gs.get, this);
				}
				addSourceContent("");
				if(gs.set != null) {
					TranspileModule_Function.transpile(gs.set, this);
				}
				if((gs.get == null || gs.get.isInject()) && (gs.set == null || gs.set.isInject())) {
					return false;
				}
			}
			case Class(cls): {
				TranspileModule_Class.transpile(cls.get(), this, member);
				return cls.get().shouldTranspile();
			}
			case Modify(modify): {
				return TranspileModule_Modify.transpile(modify, this);
			}
			case Expression(expr): {
				TranspileModule_Expression.transpile(expr, this);
			}
			case CompilerAttribute(attr, params, pos): {
				return TranspileModule_CompilerAttribute.transpile(attr, params, pos, this);
			}
			default: return false;
		}
		return true;
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
