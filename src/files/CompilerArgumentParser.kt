package files;

class CompilerArgumentParser {
	val argData: MutableMap<String,String?>;

	constructor(args: Array<String>) {
		argData = mutableMapOf();
		parseArgs(args);
	}

	fun parseArgs(args: Array<String>) {
		val regex = Regex("^--(\\w+)(?::(.+))?$");
		for(arg in args) {
			val match = regex.matchEntire(arg);
			if(match != null) {
				val groupValues = match.groupValues;
				if(groupValues.size >= 2) {
					val key = groupValues[1];
					val value = if(groupValues.size >= 3) { groupValues[2] } else { null };
					argData[key] = value;
				}
			}
		}
	}

	fun contains(key: String): Boolean {
		return argData.containsKey(key);
	}

	fun containsValue(key: String): Boolean {
		return argData.containsKey(key) && argData[key] != null;
	}

	fun getValue(key: String): String? {
		return argData[key];
	}
}
