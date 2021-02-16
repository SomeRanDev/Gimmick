package basic;

#if cpp

abstract IntRef(cpp.RawPointer<Int>) from cpp.RawPointer<Int> to cpp.RawPointer<Int> {
	@:from
	public static inline function fromValue(value: Int): IntRef {
		return cpp.RawPointer.addressOf(value);
	}

	@:to
	public function toIntRef(): cpp.Reference<Int> {
		return untyped __cpp__("*this1");
	}

	@:to
	public inline function toInt(): Int {
		return untyped toIntRef();
	}

	public function setValue(input: Int) {
		untyped __cpp__("(*this1) = input");
	}
}

#elseif hl

using hl.Ref;

abstract IntRef(hl.Ref<Int>) from hl.Ref<Int> to hl.Ref<Int> {
	@:from
	public static inline function fromValue(value: Int): IntRef {
		return hl.Ref.make(value);
	}

	@:to
	public inline function toInt(): Int {
		return this.get();
	}

	public inline function setValue(input: Int) {
		this.set(input);
	}
}

#end
