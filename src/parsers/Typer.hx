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

import parsers.error.Error;
import parsers.error.ErrorType;

using parsers.expr.TypedExpression;
using parsers.expr.QuantumExpression;
import parsers.expr.Position;

import parsers.typing.ReturnSweepContext;

class Typer {
	public var parser(default, null): Parser;

	var typeless: Bool;
	var isInterpret: Bool;

	public function new(parser: Parser) {
		this.parser = parser;
		typeless = false;
		isInterpret = true;

		@:privateAccess for(attr in parser.scope.attributes) {
			final a = attr.toAttribute();
			if(a.members != null) {
				parser.scope.push();
				for(mem in a.members) {
					parser.scope.addMemberToCurrentScope(mem);
				}
				if(a.params != null) {
					for(arg in a.params) {
						final v = new VariableMember(arg.name, arg.getType(), true, false, arg.position, null, null, ClassMember);
						parser.scope.addMemberToCurrentScope(new ScopeMember(Variable(v.getRef())));
					}
				}
				a.members = typeScope(a.members, null);
				parser.scope.pop();
			}
		}

		isInterpret = false;
	}

	public function typeScopeCollection(members: ScopeMemberCollection, addMainFunction: Bool) {
		@:privateAccess members.members = typeScopeNoPush(null, members, false);
		if(addMainFunction) {
			parser.scope.commitMainFunction();
			/*if(parser.scope.mainFunction != null) {
				members.members.push(new ScopeMember(Function(parser.scope.mainFunction.getRef())));
			}*/
		}
	}

	public function typeScopeNoPush(members: Null<Array<ScopeMember>>, collection: Null<ScopeMemberCollection>, replace: Bool, thisType: Null<Type> = null): Array<ScopeMember> {
		final allMembers: Array<ScopeMember> = [];
		if(members == null) {
			if(collection == null) return [];
			members = collection.members;
		}
		for(i in 0...members.length) {
			final mem = members[i];
			var returnToTyped = false;
			if(!typeless) {
				typeless = mem.isUntyped();
				returnToTyped = typeless;
			}
			final result = typeScopeMember(mem, replace ? i : null, thisType);
			if(result != null) {
				if(collection != null) {
					collection.members[i] = result;
				}
				allMembers.push(result);
			}
			if(returnToTyped) {
				typeless = false;
			}
		}
		return allMembers;
	}

	public function typeScope(members: Null<Array<ScopeMember>>, collection: Null<ScopeMemberCollection>, thisType: Null<Type> = null, extraMembers: Null<Array<ScopeMember>> = null): Array<ScopeMember> {
		parser.scope.push();
		if(collection != null) {
			for(mem in collection.members) {
				parser.scope.addMember(mem);
			}
		}
		if(extraMembers != null) {
			for(mem in extraMembers) {
				parser.scope.addMember(mem);
			}
		}
		final result = typeScopeNoPush(members, collection, collection != null, thisType);
		parser.scope.pop();
		return result;
	}

	public function typeScopeMember(member: ScopeMember, replacementIndex: Null<Int>, thisType: Null<Type> = null): Null<ScopeMember> {
		final registerScopeMember = function(member: ScopeMember) {
			if(!parser.scope.isTopLevel()) {
				if(replacementIndex != null) {
					parser.scope.replaceMember(replacementIndex, member);
				} else {
					parser.scope.addMember(member);
				}
			}
		}

		switch(member.type) {
			case Expression(expr): {
				final typedExpr = typeExpressionMember(expr, thisType);
				if(typedExpr != null) {
					final file = parser.scope.file;
					@:privateAccess {
						member.type = Expression(typedExpr);
						if(parser.scope.stackSize == 1 && file.usesMainFunction()) {
							parser.scope.ensureMainExists();
							if(parser.scope.mainFunction != null) {
								parser.scope.mainFunction.addMember(member);
							}
							return null;
						} else {
							return member;
						}
					}
				} else {
					return null;
				}
			}
			case Namespace(namespace): {
				final namespaceMember = namespace.get();
				typeScopeCollection(namespaceMember.members, false);
				return member;
			}
			case Variable(vari): {
				final untypedExpr = vari.get().expression;
				if(untypedExpr != null) {
					final quantumTypedExpr = untypedExpr.typeExpression(parser, typeless, isInterpret, thisType);
					var typedExpr: Null<TypedExpression> = null;
					if(quantumTypedExpr != null) {
						switch(quantumTypedExpr) {
							case Typed(texpr): {
								vari.get().setTypedExpression(texpr);
								final assignError = vari.get().canBeAssigned(texpr.getType());
								if(assignError == null) {
									vari.get().setTypeIfUnknown(texpr.getType());
								} else {
									final pos = vari.get().assignPosition;
									if(pos != null) {
										Error.addErrorFromPos(assignError, pos, [vari.get().type.toString(), texpr != null ? texpr.getType().toString() : ""]);
									}
									return null;
								}
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

					registerScopeMember(varMember);
					return varMember;
				} else {
					registerScopeMember(member);
					return member;
				}
			}
			case Function(func): {
				final funcMember = func.get();
				funcMember.type.get().resolveUnknownTypes(parser);
				final varMembers = funcMember.type.get().arguments.map(a -> new ScopeMember(Variable(a.toVarMember().getRef())));
				@:privateAccess funcMember.members = typeScope(funcMember.members, null, thisType, varMembers);
				discoverReturnType(funcMember);
				registerScopeMember(member);
				return member;
			}
			case PrefixOperator(_, func) | SuffixOperator(_, func) | InfixOperator(_, func) | CallOperator(_, func): {
				final funcMember = func.get();
				funcMember.type.get().resolveUnknownTypes(parser);
				final varMembers = funcMember.type.get().arguments.map(a -> new ScopeMember(Variable(a.toVarMember().getRef())));
				@:privateAccess funcMember.members = typeScope(funcMember.members, null, thisType, varMembers);
				discoverReturnType(funcMember);
				registerScopeMember(member);
				return member;
			}
			case Class(cls): {
				final clsMemberType = cls.get().type.get();
				clsMemberType.members.classSort();
				@:privateAccess clsMemberType.members.setAllMembers(typeScope(null, clsMemberType.members, Type.Pointer(Type.Class(cls.get().type, null))));
				registerScopeMember(member);
				return member;
			}
			case GetSet(getset): {
				final getsetMember = getset.get();
				if(getsetMember.get != null) {
					@:privateAccess getsetMember.get.members = typeScope(getsetMember.get.members, null, thisType);
				}
				if(getsetMember.set != null) {
					@:privateAccess getsetMember.set.members = typeScope(getsetMember.set.members, null, thisType);
				}
				registerScopeMember(member);
				return member;
			}
			case Modify(modify): {
				if(modify.members != null) {
					final mems = [];
					for(mem in modify.members) {
						mems.push(mem);
					}
					typeScope(mems, null, modify.type);
				}
			}
			default: {}
		}
		return member;
	}

	public function typeExpressionMember(inputExpr: ExpressionMember, thisType: Null<Type>): Null<ExpressionMember> {
		switch(inputExpr.type) {
			case Basic(expr): {
				final typed = expr.typeExpression(parser, typeless, isInterpret, thisType);
				if(typed != null) {
					return new ExpressionMember(Basic(typed), inputExpr.position);
				} else {
					return null;
				}
			}
			case Scope(subExpressions): {
				return new ExpressionMember(Scope(typeScope(subExpressions, null)), inputExpr.position);
			}
			case IfStatement(expr, subExpressions, checkTrue): {
				final typed = expr.typeExpression(parser, typeless, isInterpret, thisType);
				if(typed != null) {
					return new ExpressionMember(IfStatement(typed, typeScope(subExpressions, null), checkTrue), inputExpr.position);
				} else {
					return null;
				}
			}
			case IfElseStatement(ifState, elseExpressions): {
				final exprMember = typeExpressionMember(ifState, thisType);
				if(exprMember != null) {
					return new ExpressionMember(IfElseStatement(exprMember, typeScope(elseExpressions, null)), inputExpr.position);
				} else {
					return null;
				}
			}
			case IfElseIfChain(ifStatements, elseExpressions): {
				final typedIfStatements: Array<ExpressionMember> = [];
				for(ifState in ifStatements) {
					final typedIf = typeExpressionMember(ifState, thisType);
					if(typedIf != null) {
						typedIfStatements.push(typedIf);
					}
				}
				if(typedIfStatements.length > 0) {
					return new ExpressionMember(IfElseIfChain(typedIfStatements, elseExpressions == null ? null : typeScope(elseExpressions, null)), inputExpr.position);
				} else {
					return null;
				}
			}
			case Loop(expr, subExpressions, checkTrue): {
				var typedExpr: Null<QuantumExpression> = null;
				if(expr != null) {
					typedExpr = expr.typeExpression(parser, typeless, isInterpret, thisType);
				}
				return new ExpressionMember(Loop(expr == null ? null : typedExpr, typeScope(subExpressions, null), checkTrue), inputExpr.position);
			}
			case ReturnStatement(e): {
				if(e != null) {
					final typed = e.typeExpression(parser, typeless, isInterpret, thisType);
					if(typed != null) {
						return new ExpressionMember(ReturnStatement(typed), inputExpr.position);
					} else {
						return null;
					}
				}
				return inputExpr;
			}
			default: {}
		}
		return inputExpr;
	}

	public function discoverReturnType(funcMember: FunctionMember) {
		var returnType: Null<Type> = funcMember.type.get().returnType;
		if(returnType.isVoid()) {
			returnType = null;
		}
		final context = new ReturnSweepContext(returnType);
		if(!ReturnSweepContext.findReturnStatementFromMembers(funcMember.members, context)) {
			if(returnType != null) {
				Error.addErrorFromPos(ErrorType.NoReturnOnFunction, funcMember.declarePosition);
			}
		}
		if(returnType == null && context.expectedTypeKnown && context.expectedType != null) {
			funcMember.type.get().discoverReturnType(context.expectedType);
		}
	}
}
