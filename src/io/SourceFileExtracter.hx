package io;

import haxe.io.Path;
import sys.FileSystem;

import io.SourceFilePathInfo;
import io.SourceFolderInfo;

class SourceFileExtracter {
	var basePath: String;
	var sourceFiles: Array<SourceFilePathInfo>;

	static final fileExtensions: Array<String> = ["gim", "gimmick"];

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
					final ext = path.ext;
					if(ext != null && fileExtensions.contains(ext)) {
						final importPath = relativePath.substring(0, relativePath.length - (ext.length + 1));
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

	public static function getSourceFolders(argParser: CompilerArgumentParser): Array<SourceFolderInfo> {
		final sourcePaths = argParser.getValuesOr("src", ["."]);
		final result = sourcePaths.map(path -> new SourceFolderInfo(path, Source));
		#if (sys || hxnodejs)
		final apiFolder = argParser.getValueOr("api", getApiFolder());
		result.insert(0, new SourceFolderInfo(apiFolder, Api));
		#end
		return result;
	}
}