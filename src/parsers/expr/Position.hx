package parsers.expr;

import ast.SourceFile;

class Position {
	public var file(default, null): SourceFile;
	public var line(default, null): Int;
	public var startIndex(default, null): Int;
	public var endIndex(default, null): Int;

	public static final BLANK = new Position(SourceFile.BLANK, 0, 0, 0);

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

	public function merge(...otherPositions: Null<Position>): Position {
		var smallestLine = line;
		var smallestIndex = startIndex;
		var largestIndex = endIndex;
		for(pos in otherPositions) {
			if(pos != null) {
				if(pos.line < smallestLine) smallestLine = pos.line;
				if(pos.startIndex < smallestIndex) smallestIndex = pos.startIndex;
				if(pos.endIndex > largestIndex) largestIndex = pos.endIndex;
			}
		}
		return new Position(file, smallestLine, smallestIndex, largestIndex);
	}
}
