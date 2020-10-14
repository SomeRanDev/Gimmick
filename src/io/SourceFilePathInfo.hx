package io;

class SourceFilePathInfo {
	public var fullPath(default, null): String;
	public var relativePath(default, null): String;
	public var importPath(default, null): String;
	public var fileName(default, null): String;

	public function new(full: String, relative: String, importP: String, name: String) {
		fullPath = full;
		relativePath = relative;
		importPath = importP;
		fileName = name;
	}

	public function toString() {
		return "[SourceFilePathInfo (fullPath: \"" + fullPath + "\", relativePath: \"" + relativePath + "\", importPath: \"" + importPath + "\")]";
	}
}