package ast.scope.members;

import basic.Ref;

import ast.scope.members.ClassOption;

import ast.typing.ClassType;

class ClassMember {
	public var name(default, null): String;
	public var type(default, null): Ref<ClassType>;
	public var memberLocation(default, null): MemberLocation;

	public var options(default, null): Array<ClassOption>;

	var ref: Null<Ref<ClassMember>>;

	public function new(name: String, type: Ref<ClassType>, memberLocation: MemberLocation, options: Array<ClassOption>) {
		this.name = name;
		this.type = type;
		this.memberLocation = memberLocation;
		this.options = options;
	}

	public function getRef(): Ref<ClassMember> {
		if(ref == null) {
			ref = new Ref<ClassMember>(this);
		}
		return ref;
	}

	public function isExtern() {
		return options.contains(Extern);
	}

	public function shouldTranspile() {
		return !isExtern();
	}
}
