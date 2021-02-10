package basic;

@:generic
class Tuple2<T, U> {
	public var a: T;
	public var b: U;

	public function new(a: T, b: U) {
		this.a = a;
		this.b = b;
	}

	#if macro
	public macro test(): Expr {

	}
	#end
}
