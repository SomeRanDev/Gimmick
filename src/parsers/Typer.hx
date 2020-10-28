package parsers;

import basic.Ref;

import ast.scope.ScopeMember;
import ast.scope.ExpressionMember;
import ast.scope.ScopeMemberCollection;
import ast.scope.members.FunctionMember;
import ast.scope.members.VariableMember;
import ast.typing.FunctionType;
import ast.typing.Type;

import parsers.Parser;
using parsers.expr.TypedExpression;
using parsers.expr.QuantumExpression;

class Typer {
	public var parser(default, null): Parser;

	var typeless: Bool;

	public function new(parser: Parser) {
		this.parser = parser;
		typeless = false;

		@:privateAccess for(attr in parser.scope.attributes) {
			final a = attr.toAttribute();
			if(a.members != null) {
				parser.scope.push();
				for(mem in a.members) {
					parser.scope.addMemberToCurrentScope(mem);
				}
				if(a.params != null) {
					for(arg in a.params) {
						final v = new VariableMember(arg.name, arg.getType(), true, arg.position, null, ClassMember);
						parser.scope.addMemberToCurrentScope(new ScopeMember(Variable(v.getRef())));
					}
				}
				a.members = typeScope(a.members);
				parser.scope.pop();
			}
		}
	}

	public function typeScopeCollection(members: ScopeMemberCollection, addMainFunction: Bool) {
		@:privateAccess members.members = typeScopeNoPush(members.members);
		if(addMainFunction) {
			parser.scope.commitMainFunction();
			/*if(parser.scope.mainFunction != null) {
				members.members.push(new ScopeMember(Function(parser.scope.mainFunction.getRef())));
			}*/
		}
	}

	public function typeScopeNoPush(members: Array<ScopeMember>): Array<ScopeMember> {
		final allMembers: Array<ScopeMember> = [];
		for(i in 0...members.length) {
			final mem = members[i];
			var returnToTyped = false;
			if(!typeless) {
				typeless = mem.isUntyped();
				returnToTyped = typeless;
			}
			final result = typeScopeMember(mem);
			if(result != null) {
				//members[i] = result;
				allMembers.push(result);
			}
			if(returnToTyped) {
				typeless = false;
			}
		}
		return allMembers;
	}

	public function typeScope(members: Array<ScopeMember>): Array<ScopeMember> {
		parser.scope.push();
		final result = typeScopeNoPush(members);
		parser.scope.pop();
		return result;
	}

	public function typeScopeMember(member: ScopeMember): Null<ScopeMember> {
		switch(member.type) {
			case Expression(expr): {
				final typedExpr = typeExpressionMember(expr);
				if(typedExpr != null) {
					final file = parser.scope.file;
					@:privateAccess member.type = Expression(typedExpr);
					@:privateAccess if(parser.scope.stackSize == 1 && file.usesMainFunction()) {
						/*if(parser.scope.mainFunction == null) {
							final funcType = new FunctionType([], Type.Number(Int));
							parser.scope.mainFunction = new FunctionMember(file.getMainFunctionName(), funcType.getRef(), TopLevel(null));
							if(file.isMain) {
								parser.scope.mainFunction.incrementCallCount();
							}
						}*/
						parser.scope.ensureMainExists();
						if(parser.scope.mainFunction != null) {
							parser.scope.mainFunction.addMember(member);
						}
						return null;
					} else {
						return member;
					}
				} else {
					return null;
				}
			}
			case Namespace(namespace): {
				final namespaceMember = namespace.get();
				typeScopeCollection(namespaceMember.members, false);
				//@:privateAccess namespaceMember.members = typeScope(funcMember.members, parser);
				//parser.scope.addMember(member);
				return member;
				//pushMutlipleNamespaces
			}
			case Variable(vari): {
				final untypedExpr = vari.get().expression;
				if(untypedExpr != null) {
					final quantumTypedExpr = untypedExpr.typeExpression(parser, typeless);
					var typedExpr: Null<TypedExpression> = null;
					if(quantumTypedExpr != null) {
						switch(quantumTypedExpr) {
							case Typed(texpr): {
								vari.get().setTypedExpression(texpr);
								vari.get().setTypeIfUnknown(texpr.getType());
								typedExpr = texpr;
							}
							default: {}
						}
					}
				}

				final file = parser.scope.file;
				@:privateAccess if(vari.get().shouldSplitAssignment() && parser.scope.stackSize == 1 && file.usesMainFunction()) {
					final varMember = new ScopeMember(Variable(new Ref(vari.get().cloneWithoutExpression())));
					varMember.setAttributes(member.attributes);
					//attachAttributesToMember(varMember, false);
					//addNormalTopLevelMember(varMember);

					// add expression
					final expr = vari.get().constructAssignementExpression();
					if(expr != null) {
						parser.scope.ensureMainExists();
						if(parser.scope.mainFunction != null) {
							final exprMember = new ScopeMember(Expression(expr));
							exprMember.setAttributes(member.attributes);
							parser.scope.mainFunction.addMember(exprMember);
						}
					}

					parser.scope.addMember(varMember);
					return varMember;
				} else {
					parser.scope.addMember(member);
					return member;
				}
			}
			case Function(func): {
				final funcMember = func.get();
				@:privateAccess funcMember.members = typeScope(funcMember.members);
				parser.scope.addMember(member);
				return member;
			}
			case GetSet(getset): {
				final getsetMember = getset.get();
				if(getsetMember.get != null) {
					@:privateAccess getsetMember.get.members = typeScope(getsetMember.get.members);
				}
				if(getsetMember.set != null) {
					@:privateAccess getsetMember.set.members = typeScope(getsetMember.set.members);
				}
				parser.scope.addMember(member);
				return member;
			}
			default: {}
		}
		return member;
	}

	public function typeExpressionMember(expr: ExpressionMember): Null<ExpressionMember> {
		switch(expr) {
			case Basic(expr): {
				final typed = expr.typeExpression(parser, typeless);
				if(typed != null) {
					return Basic(typed);
				} else {
					return null;
				}
			}
			case Scope(subExpressions): {
				return Scope(typeScope(subExpressions));
			}
			case IfStatement(expr, subExpressions, checkTrue): {
				final typed = expr.typeExpression(parser, typeless);
				if(typed != null) {
					return IfStatement(typed, typeScope(subExpressions), checkTrue);
				} else {
					return null;
				}
			}
			case IfElseStatement(ifState, elseExpressions): {
				final exprMember = typeExpressionMember(ifState);
				if(exprMember != null) {
					return IfElseStatement(exprMember, typeScope(elseExpressions));
				} else {
					return null;
				}
			}
			case IfElseIfChain(ifStatements, elseExpressions): {
				final typedIfStatements: Array<ExpressionMember> = [];
				for(ifState in ifStatements) {
					final typedIf = typeExpressionMember(ifState);
					if(typedIf != null) {
						typedIfStatements.push(typedIf);
					}
				}
				if(typedIfStatements.length > 0) {
					return IfElseIfChain(typedIfStatements, elseExpressions == null ? null : typeScope(elseExpressions));
				} else {
					return null;
				}
			}
			case Loop(expr, subExpressions, checkTrue): {
				var typedExpr: Null<QuantumExpression> = null;
				if(expr != null) {
					typedExpr = expr.typeExpression(parser, typeless);
				}
				return Loop(expr == null ? null : typedExpr, typeScope(subExpressions), checkTrue);
			}
			case ReturnStatement(expr): {
				final typed = expr.typeExpression(parser, typeless);
				if(typed != null) {
					return ReturnStatement(typed);
				} else {
					return null;
				}
			}
			default: {}
		}
		return expr;
	}
}
