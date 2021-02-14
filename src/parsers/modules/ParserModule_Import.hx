package parsers.modules;

import basic.Ref;

import ast.scope.Scope;
import ast.scope.members.FunctionMember;

import parsers.error.Error;
import parsers.error.ErrorType;
import parsers.modules.ParserModule;

class ParserModule_Import extends ParserModule {
	public static var it = new ParserModule_Import();

	public override function parse(parser: Parser): Null<Module> {
		if(parser.parseWord("import")) {
			parser.parseWhitespaceOrComments();

			final pathStart = parser.getIndexFromLine();
			final path = parser.parseContentUntilCharOrNewLine([";"]);
			final hitSemicolon = parser.hitCharFlag;
			final file = parser.manager.beginParseFromPath(path);
			if(file == null) {
				Error.addError(ErrorType.UnknownImportPath, parser, pathStart);
			} else {
				// TODO: Add parsed file content to context.
				if(file.scope != null) {
					final myScope: Scope = file.scope;
					parser.scope.addImport(new Ref(myScope));
				}
			}

			var result: Null<Ref<FunctionMember>> = null;
			if(file != null && file.scope != null) {
				final mainFunc: Null<FunctionMember> = file.scope.getMainFunction();
				if(mainFunc != null) {
					final bla: FunctionMember = mainFunc;
					result = new Ref(bla);
				}
			}

			if(!parser.parseNextExpressionEnd()) {
				Error.addError(ErrorType.UnexpectedCharacter, parser, parser.getIndexFromLine());
				return Nothing;
			}
			
			return Import(path, result);
		}
		return null;
	}
}
