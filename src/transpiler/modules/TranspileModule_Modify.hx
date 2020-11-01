package transpiler.modules;

import ast.scope.members.ModifyMember;

class TranspileModule_Modify {
	public static function transpile(modify: ModifyMember, transpiler: Transpiler) {
		if(modify.members != null) {
			for(member in modify.members) {
				transpiler.transpileMember(member);
			}
		}
	}
}
