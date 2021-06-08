package basic;

@:generic
function or<T>(value: Null<T>, other: T): T {
	return value != null ? value : other;
}
