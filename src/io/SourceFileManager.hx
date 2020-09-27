package io;

import ast.SourceFile;

class SourceFileManager {
	var pathList: Array<String>;
	var sourceFiles: Map<String, Array<SourceFile>>;
	var currPath: Null<String>;
	var parsingHistory: Array<SourceFile>;

	public function new() {
		pathList = [];
		sourceFiles = [];
		currPath = null;
		parsingHistory = [];
	}

	public function addPath(path: String) {
		pathList.push(path);
		createPathStorage(path);
		createPathFiles(path);
	}

	function createPathStorage(path: String) {
		sourceFiles[path] = [];
	}

	function createPathFiles(path: String) {
		final srcParser = new SourceFileExtracter(path);
		for(file in srcParser.getFiles()) {
			sourceFiles[path].push(new SourceFile(file));
		}
	}

	function parseFile(file: SourceFile) {
		if(!parsingHistory.contains(file)) {
			parsingHistory.push(file);
			file.parseFile(this);
			parsingHistory.pop();
		}
	}

	public function beginParse() {
		for(path in pathList) {
			currPath = path;
			final files = sourceFiles[path];
			for(file in files) {
				parseFile(file);
			}
		}
		currPath = null;
	}

	public function beginParseFromPath(path: String): Null<SourceFile> {
		final file = findFileFromRelativePath(path);
		if(file != null) {
			parseFile(file);
		}
		return file;
	}

	public function findFileFromRelativePath(path: String): Null<SourceFile> {
		// The current path being parsed takes presidence
		if(currPath != null) {
			final files = sourceFiles[currPath];
			for(file in files) {
				if(file.matchesRelativePath(path)) {
					return file;
				}
			}
		}

		// Check all other paths
		for(path in pathList) {
			if(path != currPath) {
				final files = sourceFiles[path];
				for(file in files) {
					if(file.matchesRelativePath(path)) {
						return file;
					}
				}
			}
		}
		return null;
	}
}
