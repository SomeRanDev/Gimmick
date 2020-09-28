package ast;

import sys.io.File;
import sys.FileSystem;

import io.SourceFilePathInfo;
import io.SourceFileManager;

import parsers.Parser;

class SourceFile {
	public var source(default, null): String;
	public var pathInfo(default, null): SourceFilePathInfo;

	var isParsed = false;

	public function new(pathInfo: SourceFilePathInfo) {
		source = "";
		this.pathInfo = pathInfo;
		loadSourceFromFile();
	}

	function loadSourceFromFile() {
		#if (sys || hxnodejs)
		final fullPath = pathInfo.fullPath;
		if(FileSystem.exists(fullPath)) {
			source = File.getContent(fullPath);
		}
		#end
	}

	function loadSourceFromString(content: String) {
		source = content;
	}

	public function parseFile(manager: SourceFileManager) {
		if(!isParsed) {
			final parser = new Parser(source, manager, this);
			parser.setMode_SourceFile();
			parser.beginParse();
			isParsed = true;
		}
	}

	public function matchesRelativePath(path: String): Bool {
		return path == pathInfo.importPath;
	}
}
