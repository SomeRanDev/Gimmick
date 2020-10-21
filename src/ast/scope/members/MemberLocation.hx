package ast.scope.members;

enum MemberLocation {
	TopLevel(namespace: Null<Array<String>>);
	ClassMember;
}
