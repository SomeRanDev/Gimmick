import files.CompilerArgumentParser;

fun GimmickMain(args: Array<String>) {
	val argParser = CompilerArgumentParser(args);
	if(argParser.containsValue("src")) {
		val sourcePath = argParser.getValue("src");
	}
	if(argParser.containsValue("out")) {
		val outputPath = argParser.getValue("out");
	}
}
