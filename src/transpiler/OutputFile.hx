package transpiler;

using StringTools;

import ast.SourceFile;
import ast.scope.ScopeMemberCollection;

using transpiler.Language;
import transpiler.Transpiler;
import transpiler.OutputSourceFile;
import transpiler.OutputHeaderFile;
import transpiler.TranspilerOptions;

class OutputFile {
	var source: SourceFile;
	var transpiler: Transpiler;

	var headerFile: OutputHeaderFile;
	var sourceFile: OutputSourceFile;

	public function new(source: SourceFile, language: Language) {
		this.source = source;

		final members = source.members;
		headerFile = new OutputHeaderFile();
		sourceFile = new OutputSourceFile();
		transpiler = new Transpiler(members == null ? new ScopeMemberCollection() : members, headerFile, sourceFile, language);

		preTranspile(language);
		start();
		postTranspile(language);
	}

	function preTranspile(language: Language) {
		if(language.isCpp()) {
			setupHeaderGuardsCpp();
			setupHeaderIncludeCpp(language);
			setupAutoIncludesCpp();
		}
	}

	function setupHeaderGuardsCpp() {
		if(TranspilerOptions.pragmaHeaderGuard) {
			headerFile.addContent("#pragma once");
		} else {
			final headerMacroName = source.macroGuardName();
			headerFile.addContent("#ifndef " + headerMacroName + "\n");
			headerFile.addContent("#define " + headerMacroName + "\n");
		}
	}

	function setupHeaderIncludeCpp(language: Language) {
		sourceFile.addContent("#include \"" + source.pathInfo.fileName + language.headerFileExtension() + "\"\n");
	}

	function setupAutoIncludesCpp() {
		final requiredIncludes = source.getRequiredIncludes();
		var headerResult = "";
		var sourceResult = "";
		for(include in requiredIncludes) {
			final path = if(include.brackets) {
				"<" + include.path + ">";
			} else {
				"\"" + include.path + "\"";
			};
			if(include.header) {
				headerResult += "#include " + path + "\n";
			} else {
				sourceResult += "#include " + path + "\n";
			}
		}
		if(headerResult.length > 0) {
			headerFile.addContent("\n" + headerResult + "");
		}
		if(sourceResult.length > 0) {
			sourceFile.addContent("\n" + sourceResult + "");
		}
	}

	function start() {
		transpiler.transpile();
	}

	function postTranspile(language: Language) {
		if(language.isCpp()) {
			if(!TranspilerOptions.pragmaHeaderGuard) {
				headerFile.addContent("\n#endif\n");
			}
		}
	}

	public function output(): Map<String,String> {
		if(hasHeader()) {
			return [
				source.getSourceOutputFile() => getSource(),
				source.getHeaderOutputFile() => getHeader()
			];
		} else {
			return [
				source.getSourceOutputFile() => getSource()
			];
		}
	}

	public function hasHeader(): Bool {
		return transpiler.context.isCpp();
	}

	public function getHeader(): String {
		return headerFile.getContent();
	}

	public function getSource(): String {
		return sourceFile.getContent();
	}
}
