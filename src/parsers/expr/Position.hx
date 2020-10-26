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

	public function clone(): Position {
		return new Position(file, line, startIndex, endIndex);
	}

	public static function empty(file: SourceFile): Position {
		return new Position(file, 0, 0, 0);
	}

	public function toString(): String {
		return file + " " + line + " " + startIndex + " " + endIndex;
	}
}
