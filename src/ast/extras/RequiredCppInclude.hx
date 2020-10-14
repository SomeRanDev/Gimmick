package ast.extras;

class RequiredCppInclude {
	public var path(default, null): String;
	public var header(default, null): Bool;
	public var brackets(default, null): Bool;

	public function new(path: String, header: Bool, brackets: Bool) {
		this.path = path;
		this.header = header;
		this.brackets = brackets;
	}

	public function moveToHeader() {
		header = true;
	}
}

class RequiredCppIncludeCollection {
	public var collection(default, null): Array<RequiredCppInclude>;

	var existingSourcePaths: Map<String, RequiredCppInclude>;
	var existingHeaderPaths: Map<String, RequiredCppInclude>;

	public function new() {
		collection = [];
		existingSourcePaths = [];
		existingHeaderPaths = [];
	}

	public function add(path: String, header: Bool, brackets: Bool) {
		if(header) {
			if(existingHeaderPaths.exists(path)) {
			} else if(existingSourcePaths.exists(path)) {
				final obj = existingSourcePaths.get(path);
				if(obj != null) {
					existingSourcePaths.remove(path);
					existingHeaderPaths.set(path, obj);
					obj.moveToHeader();
				}
				return;
			}
		}
		if(!existingSourcePaths.exists(path) && !existingHeaderPaths.exists(path)) {
			final obj = new RequiredCppInclude(path, header, brackets);
			existingSourcePaths.set(path, obj);
			collection.push(obj);
		}
	}
}
