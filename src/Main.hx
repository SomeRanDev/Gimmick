package;

import io.CompilerArgumentParser;
import io.SourceFileExtracter;
import io.SourceFileManager;

import parsers.Error;

class Main {
	static function main() {
		final args = #if (sys || hxnodejs) Sys.args() #else [] #end;
		final argParser = new CompilerArgumentParser(args);
		if(argParser.contains("help")) {
			return haxe.Log.trace("<TODO: write help stuff here>", null);
		}

		final sourcePaths = SourceFileExtracter.getSourceFolders(argParser);

		final manager = new SourceFileManager();
		for(path in sourcePaths) {
			manager.addPath(path);
		}

		manager.beginParse();

		if(Error.hasErrors()) {
			Error.printAllErrors();
			return;
		}

		if(argParser.containsValue("out")) {
		}
	}
}
