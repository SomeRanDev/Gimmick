package ast;

using StringTools;

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
import ast.typing.Type;
import ast.extras.RequiredCppInclude;
import ast.extras.RequiredCppInclude.RequiredCppIncludeCollection;

using transpiler.Language;

class SourceFile {
	public var isMain(default, null): Bool;
	public var source(default, null): String;
	public var pathInfo(default, null): SourceFilePathInfo;
	public var folderInfo(default, null): SourceFolderInfo;
	public var scope(default, null): Null<Scope>;
	public var members(default, null): Null<ScopeMemberCollection>;
	public var language(default, null): Language;

	public var requiredIncludes(default, null): RequiredCppIncludeCollection;

	var isParsed = 0;

	public function new(isMain: Bool, pathInfo: SourceFilePathInfo, folderInfo: SourceFolderInfo, language: Language) {
		source = "";
		this.isMain = isMain;
		this.pathInfo = pathInfo;
		this.folderInfo = folderInfo;
		this.language = language;
		requiredIncludes = new RequiredCppIncludeCollection();
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
		if(source.length == 0) return;
		if(isParsed == 0 || (isParsed == 1 && !isPrelim)) {
			final errorCount = Error.errorCount();
			final parser = new Parser(source, manager, this, isPrelim);
			parser.setupForSourceFile();
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
		return generateOutputFile(language.sourceFileExtension());
	}

	public function getHeaderOutputFile(): String {
		return generateOutputFile(language.headerFileExtension());
	}

	public function usesMainFunction(): Bool {
		return true;
	}

	public function getMainFunctionName(): String {
		if(isMain) {
			return "main";
		}
		var name = "main_" + pathInfo.importPath;
		name = removeInvalidNameSymbols(name.replace("/", "_"));
		return name;
	}

	public function macroGuardName(): String {
		var headerMacroName = getHeaderOutputFile();
		headerMacroName = headerMacroName.replace("/", "_").replace(".", "_").toUpperCase();
		headerMacroName = removeInvalidNameSymbols(headerMacroName);
		return headerMacroName;
	}

	function removeInvalidNameSymbols(input: String): String {
		final regex = ~/[^a-zA-Z0-9_]/g;
		return regex.replace(input, "");
	}

	public function onTypeUsed(type: Type, header: Bool = false) {
		switch(type.type) {
			case String: requiredIncludes.add("string", header, true);
			case Tuple(_): requiredIncludes.add("tuple", header, true);
			default: {}
		}
	}

	public function getRequiredIncludes(): Array<RequiredCppInclude> {
		return requiredIncludes.collection;
	}
}
