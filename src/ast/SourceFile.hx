package ast;

import basic.Ref;

import sys.io.File;
import sys.FileSystem;

import io.SourceFilePathInfo;
import io.SourceFileManager;
import io.SourceFolderInfo;

import parsers.Parser;
import parsers.Error;
import parsers.modules.Module;

import ast.scope.ScopeMemberCollection;

import ast.scope.Scope;

class SourceFile {
	public var source(default, null): String;
	public var pathInfo(default, null): SourceFilePathInfo;
	public var folderInfo(default, null): SourceFolderInfo;
	public var scope(default, null): Null<Scope>;
	public var members(default, null): Null<ScopeMemberCollection>;

	var isParsed = 0;

	public function new(pathInfo: SourceFilePathInfo, folderInfo: SourceFolderInfo) {
		source = "";
		this.pathInfo = pathInfo;
		this.folderInfo = folderInfo;
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

	public function parseFile(manager: SourceFileManager, isPrelim: Bool) {
		if(isParsed == 0 || (isParsed == 1 && !isPrelim)) {
			final errorCount = Error.errorCount();
			final parser = new Parser(source, manager, this, isPrelim);
			parser.setMode_SourceFile();
			parser.beginParse();
			members = parser.scope.getTopScope();
			scope = parser.scope;

			if(errorCount != Error.errorCount()) {
				// there were errors, so let's not parse this again.
				isParsed = 2;
			} else {
				isParsed = isPrelim ? 1 : 2;
			}
		}
	}

	public function matchesRelativePath(path: String): Bool {
		return path == pathInfo.importPath;
	}

	public function generateOutputFile(extension: String): String {
		final path = pathInfo.importPath;
		return folderInfo.createOutputPath(path + extension);
	}

	public function getSourceOutputFile(): String {
		return generateOutputFile(".cpp");
	}

	public function getHeaderOutputFile(): String {
		return generateOutputFile(".hpp");
	}
}
