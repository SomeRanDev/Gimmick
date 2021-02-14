package parsers.error;

import parsers.expr.Position;

class ErrorPromiseBase extends ErrorPromise {
	public var errorType(default, null): ErrorType;
	public var params(default, null): Array<String>;
	public var index(default, null): Null<Int>;

	public function new(errorType: ErrorType, params: Array<String>, index: Null<Int> = null) {
		super();
		this.errorType = errorType;
		this.params = params;
		this.index = index;
	}

	public override function completeOne(position: Position) {
		Error.addErrorFromPos(errorType, position, params.length == 0 ? null : params);
	}

	public override function completeMulti(positions: Array<Position>) {
		if(index != null && index >= 0 && index < positions.length) {
			Error.addErrorFromPos(errorType, positions[index], params.length == 0 ? null : params);
		}
	}
}
