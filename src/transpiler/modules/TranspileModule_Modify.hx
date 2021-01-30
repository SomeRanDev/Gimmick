package transpiler.modules;

import ast.scope.members.ModifyMember;

class TranspileModule_Modify {
	public static function transpile(modify: ModifyMember, transpiler: Transpiler): Bool {
		var result = false;
		if(modify.members != null) {
			for(member in modify.members) {
				if(transpiler.transpileMember(member)) {
					result = true;
				}
			}
		}
		return result;
	}
}
