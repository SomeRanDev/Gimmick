package transpiler.modules;

import basic.Ref;

import ast.scope.ScopeMember;
import ast.scope.members.ClassMember;
using ast.scope.members.MemberLocation;

import parsers.expr.Position;

import transpiler.modules.TranspileModule_Expression;
import transpiler.modules.TranspileModule_Type;

class TranspileModule_Class {
	public static function transpile(cls: ClassMember, transpiler: Transpiler, member: ScopeMember, tabLevel: Int = 0) {
		if(!cls.shouldTranspile()) {
			return;
		}

		final context = transpiler.context;
		final isCpp = context.isCpp();
		final isJs = context.isJs();

		final data = cls;
		final type = data.type.get();
		final clsHeader = "class " + cls.name + " {";
		if(isCpp) {
			transpiler.addHeaderContent(clsHeader);
		} else {
			transpiler.addSourceContent(clsHeader);
		}

		final clsMembersData: Map<String,Array<Array<ScopeMember>>> = [];

		var prevCond = true;
		for(e in type.members) {
			if(!e.shouldTranspile(context, prevCond)) { prevCond = false; continue; }
			prevCond = true;
			final section = e.getClassSection(context);
			final sectionName = section == null ? "public" : section;
			if(!clsMembersData.exists(sectionName)) {
				clsMembersData[sectionName] = [[], []];
			}
			final src = clsMembersData[sectionName];
			if(src != null) {
				switch(e.type) {
					case Variable(variable): src[0].push(e);
					case Function(func): src[1].push(e);
					default: {}
				}
			}
		}

		final sectionNames = [];
		for(sec in clsMembersData.keys()) {
			// get all section names to sort later
			sectionNames.push(sec);

			// sort variables
			final members = clsMembersData[sec];
			if(members != null) {
				haxe.ds.ArraySort.sort(members[0], function(a, b) {
					final memA = a.extractVariableMember();
					final memB = b.extractVariableMember();
					if(memA != null && memB != null) {
						if(memA.isStatic != memB.isStatic) {
							return memA.isStatic ? -1 : 1;
						} else {
							return memB.type.getTypeSize() - memA.type.getTypeSize();
						}
					}
					return 0;
				});

				final sortMembersAlphabetically = member.hasAttribute("sortMembersAlphabetically");
				haxe.ds.ArraySort.sort(members[1], function(a, b) {
					final memA = a.extractFunctionMember();
					final memB = b.extractFunctionMember();
					if(memA != null && memB != null) {
						if(memA.isStatic() != memB.isStatic()) {
							return memA.isStatic() ? -1 : 1;
						} else {
							if(sortMembersAlphabetically) {
								final nameA = memA.name.toLowerCase();
								final nameB = memB.name.toLowerCase();
								return nameA > nameB ? 1 : (nameA < nameB ? -1 : 0);
							} else {
								return 0;
							}
						}
					}
					return 0;
				});
			}
		}

		// sort section names (public, private, etc)
		haxe.ds.ArraySort.sort(sectionNames, function(a, b) {
			return if(a == "public") -1;
			else if(a == "private") -1;
			else 0;
		});

		// transpile all class content in order of sections
		for(sec in sectionNames) {
			if(sectionNames[0] != sec) {
				transpiler.addHeaderContent("");
			}
			final data = clsMembersData[sec];
			if(data != null) {
				transpiler.addHeaderContent(sec + ":");
				for(e in data[0]) {
					transpileFunctionMember(cls, e, transpiler, tabLevel + 1);
				}
				if(data[0].length > 0) {
					transpiler.addHeaderContent("");
					transpiler.addSourceContent("");
				}
				for(e in data[1]) {
					if(e != data[1][0]) {
						transpiler.addSourceContent("");
					}
					transpileFunctionMember(cls, e, transpiler, tabLevel + 1);
				}
			}
		}
		

		final clsCloser = "}" + (isCpp ? ";" : "");
		if(isCpp) {
			transpiler.addHeaderContent(clsCloser);
		} else {
			transpiler.addSourceContent(clsCloser);
		}
	}

	public static function transpileFunctionMember(cls: ClassMember, member: ScopeMember, transpiler: Transpiler, tabLevel: Int) {
		var tabs = "";
		for(i in 0...tabLevel) tabs += "\t";
		switch(member.type) {
			case Variable(variable): {
				final member = variable.get();
				final isStatic = member.isStatic;
				final assignment = TranspileModule_Variable.getAssignment(variable, transpiler.context);
				final prefix = TranspileModule_Variable.makeVariablePrefix(member, transpiler.context);
				transpiler.addHeaderContent(tabs + prefix + member.name + (isStatic ? "" : assignment) + ";");
				if(transpiler.context.isCpp() && isStatic) {
					final namespaces = member.getNamespaces();
					/*
					final namespacePrefix = if(namespaces != null) {
						transpiler.context.reverseJoinArray(namespaces, "::") + "::";
					} else {
						"";
					}
					*/
					transpiler.addSourceContent(prefix + cls.name + "::" + member.name + assignment + ";");
				}
			}
			case Function(func): {
				if(transpiler.context.isCpp()) {
					transpiler.addHeaderContent(tabs + TranspileModule_Function.transpileFunctionHeader(func.get(), transpiler.context));
				}
				transpiler.addSourceContent(TranspileModule_Function.transpileFunctionSourceTopLevel(func.get(), transpiler.context, 0, [cls.name]));
			}
			default: {}
		}
	}
}