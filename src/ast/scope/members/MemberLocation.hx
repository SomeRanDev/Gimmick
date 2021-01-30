package ast.scope.members;

enum MemberLocation {
	TopLevel(namespace: Null<Array<String>>);
	ClassMember;
}

class MemberLocationHelper {
	public static function getNamespaces(location: MemberLocation): Null<Array<String>> {
		return switch(location) {
			case TopLevel(ns): ns;
			default: null;
		}
	}
}
