package ast.scope;

import haxe.ds.GenericStack;

import basic.Ref;
import basic.Multi;

import ast.SourceFile;
import ast.scope.ExpressionMember;
import ast.scope.members.FunctionMember;
import ast.scope.members.NamespaceMember;

import ast.typing.Type;
import ast.typing.NumberType;
import ast.typing.FunctionType;

import parsers.expr.PrefixOperator;
import parsers.expr.SuffixOperator;
import parsers.expr.InfixOperator;

class Scope {
	public var file(default, null): SourceFile;

	var stack: GenericStack<ScopeMemberCollection>;
	var namespaceStack: GenericStack<NamespaceMember>;
	var namespaceStackCounter: GenericStack<Int>;
	var imports: Array<Ref<Scope>>;

	var ref: Null<Ref<Scope>>;

	var stackSize: Int;

	var mainFunction: Null<FunctionMember>;
	var currentFunction: Null<FunctionMember>;

	public function new(file: SourceFile) {
		this.file = file;
		stack = new GenericStack();
		namespaceStack = new GenericStack();
		namespaceStackCounter = new GenericStack();
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
		stackSize++;
	}

	public function pop(): Null<ScopeMemberCollection> {
		if(stackSize > 1) {
			stackSize--;
			return stack.pop();
		}
		return null;
	}

	public function addImport(imp: Ref<Scope>) {
		imports.push(imp);
		addMember(Include(imp.get().file.getHeaderOutputFile(), false));
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
			addMember(Namespace(namespace.getRef()));
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

	public function addMember(member: ScopeMember) {
		// add to existing namespace if at top-level
		if(stackSize == 1) {
			final nameFirst = namespaceStack.first();
			if(nameFirst != null) {
				nameFirst.add(member);
				return;
			}
		}

		// otherwise, add to current scope
		final first = stack.first();
		if(first != null) {
			first.add(member);
		}
	}

	public function addExpressionMember(member: ExpressionMember) {
		if(stackSize == 1) {
			if(mainFunction == null) {
				final funcType = new FunctionType([], null, Type.Number(Int));
				mainFunction = new FunctionMember("main", funcType.getRef());
			}
			mainFunction.addMember(member);
		}
	}

	public function commitMainFunction() {
		if(mainFunction != null) {
			addMember(Function(mainFunction.getRef()));
		}
	}

	public function existInCurrentScope(varName: String): Bool {
		final top = stack.first();
		if(top != null) {
			return top.find(varName) != null;
		}
		return false;
	}

	public function findTypeFromName(name: String, checkImports: Bool = true): Null<Type> {
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
				final type = imp.get().findTypeFromName(name, false);
				if(type != null) {
					return type;
				}
			}
		}

		return null;
	}

	public function findMember(name: String, checkImports: Bool = true): Null<ScopeMember> {
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
				final type = imp.get().findMember(name, false);
				if(type != null) {
					return type;
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

	function findPrimitiveType(name: String): Null<Type> {
		switch(name) {
			case "void": return Type.Void();
			case "bool": return Type.Boolean();
			case "ptr": return Type.Pointer(Type.Void());
			case "ref": return Type.Reference(Type.Void());
			case "func": return Type.UnknownFunction();
			case "ext": return Type.External(null, null);
			case "unknown": return Type.Unknown();
		}
		return null;
	}

	function findNumberType(name: String): Null<NumberType> {
		switch(name) {
			case "char": return Char;
			case "short": return Short;
			case "int": return Int;
			case "long": return Long;
			case "thicc": return Thicc;

			case "byte": return Byte;
			case "ushort": return UShort;
			case "uint": return UInt;
			case "ulong": return ULong;
			case "uthicc": return UThicc;

			case "int8": return Int8;
			case "int16": return Int16;
			case "int32": return Int32;
			case "int64": return Int64;

			case "uint8": return UInt8;
			case "uint16": return UInt16;
			case "uint32": return UInt32;
			case "uint64": return UInt64;

			case "float": return Float;
			case "double": return Double;
			case "triple": return Triple;
		}
		return null;
	}
}
