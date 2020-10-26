package transpiler;

class OutputFileContent {
	var content: String;
	var startingLength: Int;

	public function new() {
		content = "";
		startingLength = -1;
	}

	public function getContent(): String {
		return content;
	}

	public function addContent(str: String) {
		content += str;
	}

	public function getLastChar(): String {
		return content.charAt(content.length - 1);
	}

	public function hasTwoPreviousNewlines(): Bool {
		return content.length >= 2 && getLastChar() == "\n" && content.charAt(content.length - 2) == "\n";
	}
}

