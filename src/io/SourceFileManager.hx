package io;

import ast.SourceFile;

import io.OutputFileSaver;
import io.SourceFolderInfo;

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

	public function addPath(pathInfo: SourceFolderInfo) {
		pathList.push(pathInfo.path);
		createPathStorage(pathInfo);
		createPathFiles(pathInfo);
	}

	function createPathStorage(pathInfo: SourceFolderInfo) {
		sourceFiles[pathInfo.path] = [];
	}

	function createPathFiles(pathInfo: SourceFolderInfo) {
		final path = pathInfo.path;
		final srcParser = new SourceFileExtracter(path);
		for(file in srcParser.getFiles()) {
			var l = sourceFiles[path];
			if(l != null) {
				l.push(new SourceFile(file, pathInfo));
			}
		}
	}

	function parseFile(file: SourceFile, prelim: Bool = false) {
		if(!parsingHistory.contains(file)) {
			parsingHistory.push(file);
			file.parseFile(this, prelim);
			parsingHistory.pop();
		}
	}

	public function beginParse() {
		for(path in pathList) {
			currPath = path;
			final files = sourceFiles[path];
			if(files != null) {
				for(file in files) {
					parseFile(file);
				}
			}
		}
		currPath = null;
	}

	public function beginParseFromPath(path: String): Null<SourceFile> {
		final file = findFileFromRelativePath(path);
		if(file != null) {
			parseFile(file, true);
		}
		return file;
	}

	public function findFileFromRelativePath(path: String): Null<SourceFile> {
		// The current path being parsed takes presidence
		if(currPath != null) {
			final files = sourceFiles[currPath];
			if(files != null) {
				for(file in files) {
					if(file.matchesRelativePath(path)) {
						return file;
					}
				}
			}
		}

		// Check all other paths
		for(p in pathList) {
			if(p != currPath) {
				final files = sourceFiles[p];
				if(files != null) {
					for(file in files) {
						if(file.matchesRelativePath(path)) {
							return file;
						}
					}
				}
			}
		}
		return null;
	}

	public function exportFiles(outputPaths: Array<String>) {
		final saver = new OutputFileSaver(outputPaths);
		for(path in pathList) {
			final files = sourceFiles[path];
			if(files != null) {
				saver.addFiles(files);
			}
		}
		saver.transpile();
	}
}
