package ast.scope.members;

import basic.Ref;

import ast.typing.FunctionType;

import ast.scope.ScopeMember;
import ast.scope.ScopeMemberCollection;
import ast.scope.members.MemberLocation;
import ast.scope.members.FunctionOption;

import ast.typing.Type;

import parsers.expr.Operator;
import parsers.expr.Position;

class FunctionMember {
	public var scopeMember(default, null): Null<ScopeMember>;
	public var name(default, null): String;
	public var type(default, null): Ref<FunctionType>;
	public var memberLocation(default, null): MemberLocation;
	public var callCount(default, null): Int;
	public var declarePosition(default, null): Position;

	public var options(default, null): Array<FunctionOption>;
	public var members(default, null): Array<ScopeMember>;

	public var uniqueId(default, null): Int;

	var ref: Null<Ref<FunctionMember>>;

	public function new(name: String, type: Ref<FunctionType>, memberLocation: MemberLocation, options: Array<FunctionOption>, declarePosition: Position) {
		this.name = name;
		this.type = type;
		this.memberLocation = memberLocation;
		this.options = options;
		this.declarePosition = declarePosition;
		callCount = 0;
		members = [];
		uniqueId = 0;
	}

	public function setScopeMember(scopeMember: ScopeMember) {
		this.scopeMember = scopeMember;
	}

	public function toString() {
		return type.get().toString();
	}

	public function addMember(member: ScopeMember) {
		members.push(member);
	}

	public function setAllMembers(members: ScopeMemberCollection) {
		this.members = members.members;
	}

	public function getNamespaces(): Null<Array<String>> {
		return switch(memberLocation) {
			case TopLevel(namespaces): namespaces;
			default: null;
		}
	}

	public function getRef(): Ref<FunctionMember> {
		if(ref == null) {
			ref = new Ref<FunctionMember>(this);
		}
		return ref;
	}

	public function incrementCallCount() {
		callCount++;
	}

	public function isStatic() {
		return options.contains(Static);
	}

	public function isInject() {
		return options.contains(Inject);
	}

	public function isExtern() {
		return options.contains(Extern);
	}

	public function shouldTranspile() {
		return !isInject() && !isExtern();
	}

	public function isConstructor() {
		return type.get().isConstructor();
	}

	public function isDestructor() {
		return type.get().isDestructor();
	}

	public function isOperator(): Null<Operator> {
		return type.get().isOperator();
	}

	public function setUniqueId(id: Int) {
		uniqueId = id;
	}

	public function shouldHaveUniqueName(): Bool {
		return uniqueId != 0;
	}

	public function uniqueFunctionSuffix(): String {
		return "$" + Std.string(uniqueId);
	}

	public function getType(): Type {
		if(isConstructor() || isDestructor()) {
			final result = type.get().classType;
			if(result != null) {
				return Type.TypeSelf(Type.Class(result, null));
			}
		}
		return Type.Function(type, null);
	}
}
