package ast.typing;

import ast.typing.TemplateArgument;

abstract TemplateArgumentCollection(Array<TemplateArgument>) to Array<TemplateArgument> from Array<TemplateArgument> {
	public function convertTemplateType(type: Type, args: Array<Type>): Type {
		final templateName = type.isTemplate();
		if(templateName != null) {
			for(i in 0...this.length) {
				if(this[i].name == templateName) {
					if(i >= 0 && i < args.length) {
						return args[i];
					} else {
						final defaultType = this[i].defaultType;
						if(defaultType != null) {
							return defaultType;
						}
					}
				}
			}
		}
		return type;
	}

	public function convertTemplateFunctionType(type: FunctionType, args: Array<Type>): FunctionType {
		return type.applyTypeArguments(args, this);
	}
}
