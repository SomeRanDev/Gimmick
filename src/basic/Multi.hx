package basic;

@:generic
class MultiIterator<T> {
	var iterators: Array<Iterator<T>>;
	var curr: Int;

	public function new(iterators: Array<Iterator<T>>) {
		this.iterators = iterators;
		curr = 0;
	}

	public function hasNext(): Bool {
		if(curr < iterators.length) {
			return iterators[curr].hasNext();
		}
		return false;
	}

	public function next(): Null<T> {
		if(curr < iterators.length) {
			final it = iterators[curr];
			final result = it.next();
			if(!it.hasNext()) {
				curr++;
			}
			return result;
		}
		return null;
	}
}

class Multi {
	@:generic
	public static function iter<T>(...iterators: Iterator<T>) {
		return new MultiIterator(iterators.toArray());
	}
}
