package io;

class SourceFilePathInfo {
	public var fullPath(default, null): String;
	public var relativePath(default, null): String;

	public function new(full: String, relative: String) {
		fullPath = full;
		relativePath = relative;
	}

	public function toString() {
		return "[SourceFilePathInfo (fullPath: \"" + fullPath + "\", relativePath: \"" + relativePath + "\")]";
	}
}