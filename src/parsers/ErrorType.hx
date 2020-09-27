package parsers;

enum abstract ErrorType(Int) from Int to Int {
	var UnknownImportPath = 1000;

	public function getErrorMessage(): String {
		switch(this) {
			case UnknownImportPath: return "Could not find source file based on path.";
		}
		return "";
	}

	public function getErrorLabel(): String {
		switch(this) {
			case UnknownImportPath: return "gimmick file not found";
		}
		return "";
	}
}
