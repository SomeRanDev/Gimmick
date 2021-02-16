package parsers.expr;

import ast.SourceFile;

class Position {
	public var file(default, null): SourceFile;
	public var startIndex(default, null): Int;
	public var endIndex(default, null): Int;

	public static final BLANK = new Position(SourceFile.BLANK, 0, 0);

	public function new(file: SourceFile, startIndex: Int, endIndex: Int) {
		this.file = file;
		this.startIndex = startIndex;
		this.endIndex = endIndex;
	}

	public function clone(): Position {
		return new Position(file, startIndex, endIndex);
	}

	public static function empty(file: SourceFile): Position {
		return new Position(file, 0, 0);
	}

	public function toString(): String {
		return file + " " + startIndex + " " + endIndex;
	}

	public function merge(...otherPositions: Null<Position>): Position {
		var smallestIndex = startIndex;
		var largestIndex = endIndex;
		for(pos in otherPositions) {
			if(pos != null) {
				if(pos.startIndex < smallestIndex) smallestIndex = pos.startIndex;
				if(pos.endIndex > largestIndex) largestIndex = pos.endIndex;
			}
		}
		return new Position(file, smallestIndex, largestIndex);
	}

	// Using this because Rest args appear broken on JS target.
	// Should remove after future Haxe update fixes.
	public function mergeArray(otherPositions: Array<Null<Position>>): Position {
		return merge(...otherPositions);
	}
}
