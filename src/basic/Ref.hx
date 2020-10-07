package basic;

@:generic
class Ref<T> {
	public var obj(default, null): T;

	public function new(obj: T) {
		this.obj = obj;
	}

	public function get(): T {
		return obj;
	}

	public function set(v: T) {
		obj = v;
	}
}
