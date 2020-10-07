package io;

import haxe.io.Path;

enum SourceFolderType {
	Source;
	Library;
	Api;
}

class SourceFolderInfo {
	public var path(default, null): String;
	public var baseOutputPath(default, null): Null<String>;

	static var libraryPath = "lib";
	static var apiPath = "api";

	public function new(path: String, type: SourceFolderType) {
		this.path = path;
		setupBaseOutputPath(type);
	}

	function setupBaseOutputPath(type: SourceFolderType) {
		switch(type) {
			case Source: {
				baseOutputPath = null;
			}
			case Library: {
				final libName = getDirectoryName(path);
				baseOutputPath = libName == null ? libraryPath : Path.join([libraryPath, libName]);
			}
			case Api: {
				baseOutputPath = apiPath;
			}
		}
	}

	function getDirectoryName(path: String): Null<String> {
		final slashRegex = ~/[\/\\]/g;
		final dir = Path.directory(path);
		if(dir != null) {
			return slashRegex.split(dir).pop();
		}
		return null;
	}

	public function createOutputPath(relativePath: String): String {
		if(baseOutputPath == null) {
			return relativePath;
		}
		return Path.join([baseOutputPath, relativePath]);
	}
}
