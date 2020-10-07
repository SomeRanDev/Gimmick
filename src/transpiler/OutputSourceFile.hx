package transpiler;

class OutputSourceFile {
	var content: String;

	public function new() {
		content = "";
	}

	public function addContent(str: String) {
		content += str + "\n\n";
	}

	public function getContent(): String {
		return content;
	}
}
