package parsers;

import parsers.modules.ParserModule;

class ParserLevel {
	public var parsers(default, null): Array<ParserModule>;
	public var spacing(default, null): String;
	public var popOnNewline(default, null): Null<Int>;

	public function new(parsers: Array<ParserModule>, spacing: String, popOnNewline: Null<Int>) {
		this.parsers = parsers;
		this.spacing = spacing;
		this.popOnNewline = popOnNewline;
	}
}
