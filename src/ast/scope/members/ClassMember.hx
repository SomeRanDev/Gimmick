package ast.scope.members;

import basic.Ref;

import parsers.expr.TypedExpression;

import ast.scope.ScopeMember;
import ast.scope.ScopeParameterSearchResult;
import ast.scope.members.ClassOption;

import ast.typing.Type;
import ast.typing.ClassType;
import ast.typing.TemplateArgumentCollection;

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

	public function findConstructorWithParameters(params: Array<Type>): ScopeParameterSearchResult {
		return type.get().findConstructorWithParameters(params);
	}

	public function toType(): Type {
		return Type.Class(type, null);
	}

	public function applyTypeArguments(args: Array<Type>, templateArguments: Null<TemplateArgumentCollection> = null): ClassMember {
		final newType = type.get().applyTypeArguments(args, templateArguments);
		if(newType == type.get()) return this;
		return new ClassMember(name, newType.getRef(), memberLocation, options);
	}
}
