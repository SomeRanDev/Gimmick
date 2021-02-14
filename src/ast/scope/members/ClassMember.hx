package ast.scope.members;

import basic.Ref;

import parsers.expr.TypedExpression;

import ast.scope.ScopeMember;
import ast.scope.members.ClassOption;

import ast.typing.Type;
import ast.typing.ClassType;

class ClassMember {
	public var scopeMember(default, null): Null<ScopeMember>;
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

	public function setScopeMember(scopeMember: ScopeMember) {
		this.scopeMember = scopeMember;
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

	public function getAllConstructors(): Array<ScopeMember> {
		return type.get().getAllConstructors();
	}

	public function findConstructorWithParameters(params: Array<Type>): Null<Array<ScopeMember>> {
		return type.get().findConstructorWithParameters(params);
	}
}
