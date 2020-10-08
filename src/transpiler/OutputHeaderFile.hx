package transpiler;

class OutputHeaderFile {
	var content: String;

	public function new() {
		content = "";
	}

	public function getContent(): String {
		return content;
	}

	public function addContent(str: String) {
		content += str;
	}
}
