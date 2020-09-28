package io;

import haxe.io.Path;
import sys.FileSystem;

import io.SourceFilePathInfo;

class SourceFileExtracter {
	var basePath: String;
	var sourceFiles: Array<SourceFilePathInfo>;

	static final fileExtension = "gimmick";

	public function new(path: String) {
		basePath = path;
		sourceFiles = [];
		extractFiles(path, "");
	}

	function extractFiles(basePath: String, currPath: String) {
		#if (sys || hxnodejs)
		var pathStr = currPath == "" ? basePath : Path.join([basePath, currPath]);
		if(FileSystem.exists(pathStr)) {
			final files = FileSystem.readDirectory(pathStr);
			for(file in files) {
				final filePath = Path.join([pathStr, file]);
				final relativePath = currPath == "" ? file : Path.join([currPath, file]);
				if(FileSystem.isDirectory(filePath)) {
					extractFiles(basePath, relativePath);
				} else {
					final path = new Path(filePath);
					if(path.ext == fileExtension) {
						final importPath = relativePath.substring(0, relativePath.length - (path.ext.length + 1));
						sourceFiles.push(new SourceFilePathInfo(filePath, relativePath, importPath));
					}
				}
			}
		}
		#end
	}

	public function getBasePath(): String {
		return basePath;
	}

	public function getFiles(): Array<SourceFilePathInfo> {
		return sourceFiles;
	}

	public static function getApiFolder(): String {
		#if (sys || hxnodejs)
		final programPath = Sys.programPath();
		return Path.join([Path.directory(programPath), "api"]);
		#else
		return "";
		#end
	}

	public static function getSourceFolders(argParser: CompilerArgumentParser): Array<String> {
		final sourcePaths = argParser.getValuesOr("src", ["."]);
		#if (sys || hxnodejs)
		final apiFolder = argParser.getValueOr("api", getApiFolder());
		sourcePaths.insert(0, apiFolder);
		#end
		return sourcePaths;
	}
}