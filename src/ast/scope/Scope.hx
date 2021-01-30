package ast.scope;

import haxe.ds.GenericStack;

import basic.Ref;
import basic.Multi;

import ast.SourceFile;
import ast.scope.ExpressionMember;
import ast.scope.GlobalScopeMember;
import ast.scope.members.VariableMember;
import ast.scope.members.FunctionMember;
import ast.scope.members.NamespaceMember;
import ast.scope.members.AttributeMember;

import ast.typing.Type;
import ast.typing.NumberType;
import ast.typing.FunctionType;

import parsers.Parser;
import parsers.expr.TypedExpression;
import parsers.expr.Literal;
import parsers.expr.Position;
import parsers.expr.PrefixOperator;
import parsers.expr.SuffixOperator;
import parsers.expr.InfixOperator;
import parsers.expr.CallOperator;
import parsers.expr.CallOperator.CallOperators;

import parsers.modules.Module;

class Scope {
	public var file(default, null): SourceFile;

	var stack: GenericStack<ScopeMemberCollection>;
	var namespaceStack: GenericStack<NamespaceMember>;
	var namespaceStackCounter: GenericStack<Int>;
	var attributes: Array<ScopeMember>;
	var attributeInstances: GenericStack<Array<Module>>;
	var imports: Array<Ref<Scope>>;

	var ref: Null<Ref<Scope>>;

	var stackSize: Int;

	public var mainFunction: Null<FunctionMember>;

	static var globalScope: Array<GlobalScopeMember> = [];

	public function new(file: SourceFile) {
		this.file = file;
		stack = new GenericStack();
		namespaceStack = new GenericStack();
		namespaceStackCounter = new GenericStack();
		attributes = [];
		attributeInstances = new GenericStack();
		imports = [];
		stackSize = 0;
	}

	public function getRef(): Ref<Scope> {
		if(ref == null) {
			ref = new Ref<Scope>(this);
		}
		return ref;
	}

	public function getTopScope(): Null<ScopeMemberCollection> {
		var result: Null<ScopeMemberCollection> = null;
		for(s in stack) {
			result = s;
		}
		return result;
	}

	public function push() {
		stack.add(new ScopeMemberCollection());
		attributeInstances.add([]);
		stackSize++;
	}

	public function pop(): Null<ScopeMemberCollection> {
		if(stackSize > 1) {
			stackSize--;
			attributeInstances.pop();
			return stack.pop();
		}
		return null;
	}

	public function addImport(imp: Ref<Scope>) {
		imports.push(imp);
		addMember(new ScopeMember(Include(imp.get().file.getHeaderOutputFile(), false, false)));
	}

	public function pushNamespace(name: String) {
		namespaceStack.add(new NamespaceMember(name));
	}

	public function pushMutlipleNamespaces(names: Array<String>) {
		final len = names.length;
		if(len > 0) {
			for(i in 0...len) {
				pushNamespace(names[i]);
			}
			namespaceStackCounter.add(len);
		}
	}

	public function popNamespace() {
		final count = namespaceStackCounter.pop();
		if(count != null) {
			for(i in 0...count) {
				popOneNamespace();
			}
		}
	}

	public function popOneNamespace() {
		final namespace = namespaceStack.pop();
		if(namespace != null) {
			addMember(new ScopeMember(Namespace(namespace.getRef())));
		}
	}

	public function popAllNamespaces() {
		while(namespacesExist()) {
			popNamespace();
		}
	}

	public function namespacesExist(): Bool {
		return !namespaceStack.isEmpty();
	}

	public function currentNamespaceStack(): Null<Array<String>> {
		if(namespacesExist()) {
			final result = [];
			for(n in namespaceStack) {
				result.push(n.name);
			}
			return result;
		}
		return null;
	}

	public function isTopLevel(): Bool {
		return stackSize == 1;
	}

	public function addMember(member: ScopeMember) {
		attachAttributesToMember(member);
		if(isTopLevel()) {
			addTopLevelMember(member);
		} else {
			addMemberToCurrentScope(member);
		}
	}

	public function attachAttributesToMember(member: ScopeMember, clear: Bool = true) {
		final first = attributeInstances.first();
		if(first != null) {
			if(first.length != 0) {
				for(a in first) {
					switch(a) {
						case AttributeInstance(instanceOf, params, _): {
							member.addAttributeInstance(instanceOf, params);
						}
						default: {}
					}
				}
				if(clear) {
					attributeInstances.pop();
					attributeInstances.add([]);
				}
			}
		}
	}

	public function addMemberToCurrentScope(member: ScopeMember) {
		final first = stack.first();
		if(first != null) {
			first.add(member);
		}
	}

	public function addTopLevelMember(member: ScopeMember) {
		// If a variable is assigned a non-const expression
		// at the top level, we need to split it into two.
		// One for the declaration, and one for the assignment
		// in the main function itself.
		/*
		var splitVarMember: Null<VariableMember> = null;
		switch(member.type) {
			case Variable(variable): {
				if(variable.get().shouldSplitAssignment()) {
					splitVarMember = variable.get();
				}
			}
			default: {}
		}
		*/
		//if(splitVarMember != null) {
		//	addVarWithAssignTopLevelMember(splitVarMember);
		//} else {
			addNormalTopLevelMember(member);
		//}
		
	}

	public function addNormalTopLevelMember(member: ScopeMember) {
		// add to existing namespace if at top-level
		final nameFirst = namespaceStack.first();
		if(nameFirst != null) {
			nameFirst.add(member);
			return;
		}

		// otherwise, add to current scope
		addMemberToCurrentScope(member);
	}

	public function addVarWithAssignTopLevelMember(member: VariableMember) {
		// add variable init
		final varMember = new ScopeMember(Variable(new Ref(member.cloneWithoutExpression())));
		attachAttributesToMember(varMember, false);
		addNormalTopLevelMember(varMember);

		// add expression
		final expr = member.constructAssignementExpression();
		if(expr != null) {
			addExpressionMember(expr);
		}
	}

	public function ensureMainExists() {
		if(mainFunction == null) {
			final funcType = new FunctionType([], Type.Number(Int));
			mainFunction = new FunctionMember(file.getMainFunctionName(), funcType.getRef(), TopLevel(null), []);
		}
	}

	public function addExpressionMember(member: ExpressionMember) {
		/*if(stackSize == 1 && file.usesMainFunction()) {
			if(mainFunction == null) {
				final funcType = new FunctionType([], Type.Number(Int));
				mainFunction = new FunctionMember(file.getMainFunctionName(), funcType.getRef(), TopLevel(null));
				if(file.isMain) {
					mainFunction.incrementCallCount();
				}
			}
			final scopeMember = new ScopeMember(Expression(member));
			attachAttributesToMember(scopeMember);
			mainFunction.addMember(scopeMember);
		} else {
			addMember(new ScopeMember(Expression(member)));
		}*/

		final scopeMember = new ScopeMember(Expression(member));
		attachAttributesToMember(scopeMember);
		addMember(scopeMember);
	}

	public function addFunctionCallExpression(func: Ref<FunctionMember>, parser: Parser) {
		func.get().incrementCallCount();
		final literal = Literal.Name(func.get().name, null);
		final val = TypedExpression.Value(literal, parser.emptyPosition(), Type.Function(func.get().type, null, false, false));
		final expr = TypedExpression.Call(CallOperators.Call, val, [], parser.emptyPosition(), func.get().type.get().returnType);
		addExpressionMember(Basic(expr));
	}

	public function commitMainFunction() {
		if(mainFunction != null) {
			final literal = Literal.Number("0", Decimal, NumberType.Int);
			final value = TypedExpression.Value(literal, Position.empty(file), Type.Number(NumberType.Int));
			mainFunction.addMember(new ScopeMember(Expression(ExpressionMember.ReturnStatement(value))));
			addMember(new ScopeMember(Function(mainFunction.getRef())));
		}
	}

	public function getMainFunction(): Null<FunctionMember> {
		return mainFunction;
	}

	public function existInCurrentScope(varName: String): Null<ScopeMember> {
		final top = stack.first();
		if(top != null) {
			return top.find(varName);
		}
		return null;
	}

	public function existInCurrentScopeAll(varName: String): Null<Array<ScopeMember>> {
		final top = stack.first();
		if(top != null) {
			return top.findAll(varName);
		}
		return null;
	}

	public function addAttribute(attribute: AttributeMember) {
		final result = new ScopeMember(Attribute(attribute));
		attachAttributesToMember(result);
		attributes.push(result);
	}

	public function attributeExistInCurrentScope(attributeName: String): Bool {
		return findAttributeFromName(attributeName, false) != null;	
	}

	public function findAttributeFromName(attributeName: String, checkImports: Bool = true, checkGlobals: Bool = true): Null<AttributeMember> {
		for(a in attributes) {
			if(a.toAttribute().name == attributeName) {
				return a.toAttribute();
			}
		}

		if(checkImports) {
			for(imp in imports) {
				final attr = imp.get().findAttributeFromName(attributeName, false, false);
				if(attr != null) {
					return attr;
				}
			}
		}

		if(checkGlobals) {
			for(g in globalScope) {
				for(a in g.attributes) {
					if(a.toAttribute().name == attributeName) {
						return a.toAttribute();
					}
				}
			}
		}

		return null;
	}

	public function addAttributeInstance(attr: Module) {
		final first = attributeInstances.first();
		if(first != null) {
			first.push(attr);
		}
	}

	public function checkForGlobalScopeInclusion() {
		final globalMembers = [];
		final globalAttributes = [];
		final topScope = getTopScope();

		if(topScope != null) {
			var globalAll = false;
			for(scope in topScope) {
				switch(scope.type) {
					case CompilerAttribute(attr, _): {
						if(attr.name == "globalAll") {
							globalAll = true;
						}
					}
					default: {}
				}
			}
			for(attr in attributes) {
				if(globalAll || attr.isGlobal()) {
					globalAttributes.push(attr);
				}
			}
			for(scope in topScope) {
				if(globalAll || scope.isGlobal()) {
					globalMembers.push(scope);
				}
			}
		}

		if(globalMembers.length > 0 || globalAttributes.length > 0) {
			final global = new GlobalScopeMember(globalMembers, globalAttributes, this);
			globalScope.push(global);
		}
	}

	public function findTypeFromName(name: String, checkImports: Bool = true, includeGlobals: Bool = true): Null<Type> {
		final primitiveType = findPrimitiveType(name);
		if(primitiveType != null) {
			return primitiveType;
		}

		final numberType = findNumberType(name);
		if(numberType != null) {
			return Type.Number(numberType);
		}

		for(namespace in namespaceStack) {
			final clsType = namespace.members.findClassType(name);
			if(clsType != null) {
				return Type.Class(clsType, null);
			}
		}

		for(collection in stack) {
			final clsType = collection.findClassType(name);
			if(clsType != null) {
				return Type.Class(clsType, null);
			}
		}

		if(checkImports) {
			for(imp in imports) {
				final type = imp.get().findTypeFromName(name, false, false);
				if(type != null) {
					return type;
				}
			}
		}

		if(includeGlobals) {
			for(g in globalScope) {
				final type = g.scope.findTypeFromName(name, false, false);
				if(type != null) {
					file.requireInclude(g.scope.file.getHeaderOutputFile(), false);
					return type;
				}
			}
		}

		return null;
	}

	public function findMember(name: String, checkImports: Bool = true, includeGlobals: Bool = true): Null<ScopeMember> {
		for(namespace in namespaceStack) {
			final member = namespace.members.find(name);
			if(member != null) {
				return member;
			}
		}

		for(collection in stack) {
			final member = collection.find(name);
			if(member != null) {
				return member;
			}
		}

		if(checkImports) {
			for(imp in imports) {
				final type = imp.get().findMember(name, false, false);
				if(type != null) {
					return type;
				}
			}
		}

		if(includeGlobals) {
			for(g in globalScope) {
				final type = g.scope.findMember(name, false, false);
				if(type != null) {
					if(type.shouldTriggerAutomaticInclude()) {
						file.requireInclude(g.scope.file.getHeaderOutputFile(), false);
					}
					return type;
				}
			}
		}

		return null;
	}

	public function findMemberWithParameters(name: String, params: Array<TypedExpression>, checkImports: Bool = true, includeGlobals: Bool = true): Null<Array<ScopeMember>> {
		for(namespace in namespaceStack) {
			final members = namespace.members.findWithParameters(name, params);
			if(members != null) {
				return members;
			}
		}

		for(collection in stack) {
			final members = collection.findWithParameters(name, params);
			if(members != null) {
				return members;
			}
		}

		if(checkImports) {
			for(imp in imports) {
				final types = imp.get().findMemberWithParameters(name, params, false, false);
				if(types != null) {
					return types;
				}
			}
		}

		if(includeGlobals) {
			for(g in globalScope) {
				final types = g.scope.findMemberWithParameters(name, params, false, false);
				if(types != null) {
					return types;
				}
			}
		}

		return null;
	}

	public function findPrefixOperator(op: PrefixOperator, checkImports: Bool = true): Null<Type> {
		for(namespace in namespaceStack) {
			final funcType = namespace.members.findPrefixOperator(op);
			if(funcType != null) {
				return Type.Function(funcType.get().type, null);
			}
		}

		for(collection in stack) {
			final funcType = collection.findPrefixOperator(op);
			if(funcType != null) {
				return Type.Function(funcType.get().type, null);
			}
		}

		if(checkImports) {
			for(imp in imports) {
				final type = imp.get().findPrefixOperator(op, false);
				if(type != null) {
					return type;
				}
			}
		}

		return null;
	}

	public function findSuffixOperator(op: SuffixOperator, checkImports: Bool = true): Null<Type> {
		for(namespace in namespaceStack) {
			final funcType = namespace.members.findSuffixOperator(op);
			if(funcType != null) {
				return Type.Function(funcType.get().type, null);
			}
		}

		for(collection in stack) {
			final funcType = collection.findSuffixOperator(op);
			if(funcType != null) {
				return Type.Function(funcType.get().type, null);
			}
		}

		if(checkImports) {
			for(imp in imports) {
				final type = imp.get().findSuffixOperator(op, false);
				if(type != null) {
					return type;
				}
			}
		}

		return null;
	}

	public function findInfixOperator(op: InfixOperator, inputType: Type, checkImports: Bool = true): Null<Type> {
		for(namespace in namespaceStack) {
			final funcType = namespace.members.findInfixOperator(op, inputType);
			if(funcType != null) {
				return Type.Function(funcType.get().type, null);
			}
		}

		for(collection in stack) {
			final funcType = collection.findInfixOperator(op, inputType);
			if(funcType != null) {
				return Type.Function(funcType.get().type, null);
			}
		}

		if(checkImports) {
			for(imp in imports) {
				final type = imp.get().findInfixOperator(op, inputType, false);
				if(type != null) {
					return type;
				}
			}
		}

		return null;
	}

	public function findModifyFunction(type: Type, name: String, checkImports: Bool = true, includeGlobals: Bool = true): Null<ScopeMember> {
		for(namespace in namespaceStack) {
			final member = namespace.members.findModify(type, name);
			if(member != null) {
				return member;
			}
		}

		for(collection in stack) {
			final member = collection.findModify(type, name);
			if(member != null) {
				return member;
			}
		}

		if(checkImports) {
			for(imp in imports) {
				final member = imp.get().findModifyFunction(type, name, false, false);
				if(member != null) {
					return member;
				}
			}
		}

		if(includeGlobals) {
			for(g in globalScope) {
				final type = g.scope.findModifyFunction(type, name, false, false);
				if(type != null) {
					if(type.shouldTriggerAutomaticInclude()) {
						file.requireInclude(g.scope.file.getHeaderOutputFile(), false);
					}
					return type;
				}
			}
		}

		return null;
	}

	function findPrimitiveType(name: String): Null<Type> {
		switch(name) {
			case "raw": return Type.Any();
			case "void": return Type.Void();
			case "bool": return Type.Boolean();
			case "list": return Type.List(Type.Void());
			case "ptr": return Type.Pointer(Type.Void());
			case "ref": return Type.Reference(Type.Void());
			case "string": return Type.String();
			case "func": return Type.UnknownFunction();
			case "ext": return Type.External(null, null);
			case "unknown": return Type.Unknown();
		}
		return null;
	}

	function findNumberType(name: String): Null<NumberType> {
		return switch(name) {
			case "number": Any;

			case "char": Char;
			case "short": Short;
			case "int": Int;
			case "long": Long;
			case "thicc": Thicc;

			case "byte": Byte;
			case "ushort": UShort;
			case "uint": UInt;
			case "ulong": ULong;
			case "uthicc": UThicc;

			case "int8": Int8;
			case "int16": Int16;
			case "int32": Int32;
			case "int64": Int64;

			case "uint8": UInt8;
			case "uint16": UInt16;
			case "uint32": UInt32;
			case "uint64": UInt64;

			case "float": Float;
			case "double": Double;
			case "triple": Triple;

			default: null;
		}
	}
}
