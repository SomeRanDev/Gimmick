package transpiler;

import ast.SourceFile;
import ast.scope.ScopeMemberCollection;

import transpiler.Transpiler;
import transpiler.OutputSourceFile;
import transpiler.OutputHeaderFile;

class OutputFile {
	var source: SourceFile;
	var transpiler: Transpiler;

	var headerFile: OutputHeaderFile;
	var sourceFile: OutputSourceFile;

	public function new(source: SourceFile) {
		this.source = source;

		final members = source.members;
		headerFile = new OutputHeaderFile();
		sourceFile = new OutputSourceFile();
		transpiler = new Transpiler(members == null ? new ScopeMemberCollection() : members, headerFile, sourceFile);
		start();
	}

	function start() {
		transpiler.transpile();
	}

	public function output(): Map<String,String> {
		return [
			source.getSourceOutputFile() => getSource(),
			source.getHeaderOutputFile() => getHeader()
		];
	}

	public function getHeader(): String {
		return headerFile.getContent();
	}

	public function getSource(): String {
		return sourceFile.getContent();
	}
}
