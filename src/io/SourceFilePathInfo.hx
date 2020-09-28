package io;

class SourceFilePathInfo {
	public var fullPath(default, null): String;
	public var relativePath(default, null): String;
	public var importPath(default, null): String;

	public function new(full: String, relative: String, importP: String) {
		fullPath = full;
		relativePath = relative;
		importPath = importP;
	}

	public function toString() {
		return "[SourceFilePathInfo (fullPath: \"" + fullPath + "\", relativePath: \"" + relativePath + "\", importPath: \"" + importPath + "\")]";
	}
}