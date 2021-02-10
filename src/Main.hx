package;

import io.CompilerArgumentParser;
import io.SourceFileExtracter;
import io.SourceFileManager;
import io.OutputFileSaver;

import parsers.Error;

import transpiler.Language;
import transpiler.TranspilerOptions;

function main() {
	final args = #if (sys || hxnodejs) Sys.args() #else [] #end;
	final argParser = new CompilerArgumentParser(args);
	if(argParser.contains("help")) {
		return haxe.Log.trace("<TODO: write help stuff here>", null);
	}

	TranspilerOptions.init(argParser);

	final sourcePaths = SourceFileExtracter.getSourceFolders(argParser);
	final outputPaths = OutputFileSaver.getOutputFolders(argParser);

	final language = LanguageHelper.getLanguage(argParser);
	final manager = new SourceFileManager(language, argParser.getValue("main"));
	for(path in sourcePaths) {
		manager.addPath(path);
	}

	manager.beginParse();

	if(Error.hasErrors()) {
		Error.printAllErrors();
	} else {
		manager.exportFiles(outputPaths);
		if(Error.hasErrors()) {
			Error.printAllErrors();
		}
	}
}
