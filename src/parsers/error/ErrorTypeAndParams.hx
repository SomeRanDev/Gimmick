package parsers.error;

class ErrorTypeAndParamsImpl {
	public var type(default, null): ErrorType;
	public var params(default, null): Null<Array<String>>;

	public function new(type: ErrorType, params: Null<Array<String>> = null) {
		this.type = type;
		this.params = params;
	}
}

abstract ErrorTypeAndParams(ErrorTypeAndParamsImpl) from ErrorTypeAndParamsImpl to ErrorTypeAndParamsImpl {
	public function new(type: ErrorType, params: Null<Array<String>>) {
		this = new ErrorTypeAndParamsImpl(type, params);
	}

	@:from
	public static function fromErrorType(errorType: ErrorType): ErrorTypeAndParams {
		return new ErrorTypeAndParamsImpl(errorType);
	}
}
