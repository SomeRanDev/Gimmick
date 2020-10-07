package parsers.expr;

import ast.SourceFile;

class Position {
	public var file(default, null): SourceFile;
	public var line(default, null): Int;
	public var startIndex(default, null): Int;
	public var endIndex(default, null): Int;

	public function new(file: SourceFile, line: Int, startIndex: Int, endIndex: Int) {
		this.file = file;
		this.line = line;
		this.startIndex = startIndex;
		this.endIndex = endIndex;
	}
}
