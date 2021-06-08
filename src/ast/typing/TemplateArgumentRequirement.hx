package ast.typing;

import ast.scope.ScopeMember;
import ast.scope.members.VariableMember;
import ast.scope.members.FunctionMember;

import ast.typing.Type;
import ast.typing.FunctionType;

import parsers.expr.Position;

enum TemplateArgumentRequirementType {
	HasVariable(name: String, type: Type);
	HasFunction(name: String, func: FunctionType);
	HasAttribute(name: String);
	Extends(type: Type);
	Matches(template: TemplateType);
}

class TemplateArgumentRequirement {
	public var type(default, null): TemplateArgumentRequirementType;
	public var position(default, null): Position;

	public function new(type: TemplateArgumentRequirementType, position: Position) {
		this.type = type;
		this.position = position;
	}

	public function toString(): String {
		return switch(type) {
			case TemplateArgumentRequirementType.HasVariable(name, type): "has var " + name + ": " + type.toString();
			case TemplateArgumentRequirementType.HasFunction(name, funcType): {
				if(funcType.isConstructor()) {
					"has init" + funcType.toString("");
				} else {
					"has def " + name + funcType.toString("");
				}
			}
			case TemplateArgumentRequirementType.HasAttribute(name): "has attribute " + name;
			case TemplateArgumentRequirementType.Extends(type): "extends " + type.toString();
			case TemplateArgumentRequirementType.Matches(template): "matches " + template.name;
		}
	}

	public function isExtends(): Null<Type> {
		return switch(type) {
			case TemplateArgumentRequirementType.Extends(t): t;
			default: null;
		}
	}

	public function toMember(): Null<ScopeMember> {
		return switch(type) {
			case TemplateArgumentRequirementType.HasVariable(name, type): {
				final mem = new VariableMember(name, type, false, true, Position.BLANK, Position.BLANK, null, ClassMember);
				new ScopeMember(Variable(mem.getRef()));
			}
			case TemplateArgumentRequirementType.HasFunction(name, func): {
				final mem = new FunctionMember(name, func.getRef(), ClassMember, [ Extern ], Position.BLANK);
				new ScopeMember(Function(mem.getRef()));
			}
			default: null;
		}
	}

	public static function HasVariable(name: String, type: Type, position: Position): TemplateArgumentRequirement {
		return new TemplateArgumentRequirement(TemplateArgumentRequirementType.HasVariable(name, type), position);
	}

	public static function HasFunction(name: String, funcType: FunctionType, position: Position): TemplateArgumentRequirement {
		return new TemplateArgumentRequirement(TemplateArgumentRequirementType.HasFunction(name, funcType), position);
	}

	public static function HasAttribute(name: String, position: Position): TemplateArgumentRequirement {
		return new TemplateArgumentRequirement(TemplateArgumentRequirementType.HasAttribute(name), position);
	}

	public static function Extends(type: Type, position: Position): TemplateArgumentRequirement {
		return new TemplateArgumentRequirement(TemplateArgumentRequirementType.Extends(type), position);
	}

	public static function Matches(template: TemplateType, position: Position): TemplateArgumentRequirement {
		return new TemplateArgumentRequirement(TemplateArgumentRequirementType.Matches(template), position);
	}
}
