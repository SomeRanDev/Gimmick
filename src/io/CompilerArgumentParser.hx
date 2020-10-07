package io;

class CompilerArgumentParser {
	var argData: Map<String,Null<Array<String>>>;

	public function new(args: Array<String>) {
		argData = [];
		parseArguments(args);
	}

	function parseArguments(args: Array<String>) {
		final regex = ~/^--(\w+)(?::(.+))?$/i;
		for(arg in args) {
			if(regex.match(arg)) {
				final key = regex.matched(1);
				final value = regex.matched(2);
				if(!contains(key)) {
					argData[key] = [];
				}
				if(value != null) {
					final list = argData[key];
					if(list != null) {
						list.push(value);
					}
				}
			}
		}
	}

	public function contains(key: String): Bool {
		return argData.exists(key);
	}

	public function containsValue(key: String): Bool {
		return contains(key) && getValues(key) != null;
	}

	public function getValues(key: String): Null<Array<String>> {
		if(contains(key)) {
			return argData[key];
		}
		return null;
	}

	public function getValuesOr(key: String, or: Array<String>): Array<String> {
		final values = getValues(key);
		return values != null ? values : or;
	}

	public function getValue(key: String): Null<String> {
		final values = getValues(key);
		if(values != null) {
			return values.length > 0 ? values[0] : null;
		}
		return null;
	}

	public function getValueOr(key: String, or: String): String {
		final result = getValue(key);
		return result != null ? result : or;
	}
}
