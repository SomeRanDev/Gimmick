package parsers.expr;

import parsers.Parser;
import parsers.expr.Expression;
import parsers.expr.Literal;
import parsers.expr.Operator;
import parsers.expr.PrefixOperator;
import parsers.expr.PrefixOperator.PrefixOperators;
import parsers.expr.SuffixOperator;
import parsers.expr.SuffixOperator.SuffixOperators;
import parsers.expr.InfixOperator;
import parsers.expr.InfixOperator.InfixOperators;

enum ExpressionParserMode {
	Prefix;
	Value;
	Suffix;
	Infix;
}

enum ExpressionParserPiece {
	Prefix(op: PrefixOperator);
	Value(literal: Literal);
	Suffix(op: SuffixOperator);
	Infix(op: InfixOperator);
	ExpressionPlaceholder(expression: Expression);
}

class ExpressionParser {
	var parser: Parser;
	var mode: ExpressionParserMode;
	var pieces: Array<ExpressionParserPiece>;
	var expectedEndStrings: Null<Array<String>>;

	var startingIndex: Int;
	var foundExpectedString: Bool;

	public function printAll() {
		for(p in pieces) {
			switch(p) {
				case Prefix(op): trace(op.op);
				case Value(str): trace(str);
				case Suffix(op): trace(op.op);
				case Infix(op): trace(op.op);
				case ExpressionPlaceholder(expr): trace(expr);
			}
		}
	}

	public function new(parser: Parser, expectedEndStrings: Null<Array<String>> = null) {
		this.parser = parser;
		this.expectedEndStrings = expectedEndStrings;
		this.mode = Prefix;
		pieces = [];

		startingIndex = parser.getIndexFromLine();
		foundExpectedString = expectedEndStrings == null;

		parse();
	}

	public function successful() {
		return pieces.length > 0 && foundExpectedString;
	}

	function parse() {
		while(true) {
			parser.parseWhitespaceOrComments();
			switch(mode) {
				case Prefix: {
					if(!parsePrefix()) {
						mode = Value;
					}
				}
				case Value: {
					final result = parseValue();
					if(result) {
						mode = Suffix;
					} else {
						break;
					}
				}
				case Suffix: {
					if(!parseSuffix()) {
						mode = Infix;
					}
				}
				case Infix: {
					final result = parseInfix();
					if(result) {
						mode = Prefix;
					} else {
						break;
					}
				}
			}
		}
		if(expectedEndStrings != null) {
			parser.parseWhitespaceOrComments();
			for(str in expectedEndStrings) {
				if(parser.checkAhead(str)) {
					foundExpectedString = true;
				}
			}
			if(!foundExpectedString) {
				Error.addError(UnexpectedCharacterAfterExpression, parser, parser.getIndexFromLine());
			}
		}
	}

	function parsePrefix(): Bool {
		final op = checkForOperators(cast PrefixOperators.all());
		if(op != null) {
			pieces.push(ExpressionParserPiece.Prefix(cast op));
			parser.incrementIndex(op.op.length);
			return true;
		}
		return false;
	}

	function parseValue(): Bool {
		final literal = parser.parseNextLiteral();
		if(literal != null) {
			pieces.push(ExpressionParserPiece.Value(literal));
			return true;
		}
		return false;
	}

	function parseSuffix(): Bool {
		final op = checkForOperators(cast SuffixOperators.all());
		if(op != null) {
			pieces.push(ExpressionParserPiece.Suffix(cast op));
			parser.incrementIndex(op.op.length);
			return true;
		}
		return false;
	}

	function parseInfix(): Bool {
		final op = checkForOperators(cast InfixOperators.all());
		if(op != null) {
			pieces.push(ExpressionParserPiece.Infix(cast op));
			parser.incrementIndex(op.op.length);
			return true;
		}
		return false;
	}

	function checkForOperators(operators: Array<Operator>): Null<Operator> {
		var opLength = 0;
		var result: Null<Operator> = null;
		for(op in operators) {
			if(parser.checkAhead(op.op)) {
				if(opLength < op.op.length) {
					opLength = op.op.length;
					result = op;
				}
			}
		}
		return result;
	}

	public function buildExpression(): Null<Expression> {
		var parts = pieces.copy();
		var error = false;
		while(parts.length > 1) {
			final index = getNextOperatorIndex();
			if(index != null) {
				final removedPiece = removeFromArray(parts, index);
				switch(removedPiece) {
					case Prefix(op): {
						final piece = removeFromArray(parts, index);
						if(piece != null) {
							final expr = expressionPieceToExpression(piece);
							if(expr != null) {
								parts.insert(index, ExpressionPlaceholder(Prefix(op, expr)));
							} else {
								error = true;
								break;
							}
						} else {
							error = true;
							break;
						}
					}
					case Suffix(op): {
						final piece = removeFromArray(parts, index - 1);
						if(piece != null) {
							final expr = expressionPieceToExpression(piece);
							if(expr != null) {
								parts.insert(index, ExpressionPlaceholder(Suffix(op, expr)));
							} else {
								error = true;
								break;
							}
						} else {
							error = true;
							break;
						}
					}
					case Infix(op): {
						final lpiece = removeFromArray(parts, index - 1);
						final rpiece = removeFromArray(parts, index - 1);
						if(lpiece != null && rpiece != null) {
							final lexpr = expressionPieceToExpression(lpiece);
							final rexpr = expressionPieceToExpression(rpiece);
							if(lexpr != null && rexpr != null) {
								parts.insert(index - 1, ExpressionPlaceholder(Infix(op, lexpr, rexpr)));
							} else {
								error = true;
								break;
							}
						} else {
							error = true;
							break;
						}
					}
					default: {}
				}
			} else {
				error = true;
				break;
			}
		}
		if(error) {
			Error.addError(CouldNotConstructExpression, parser, startingIndex);
			return null;
		} else if(parts.length == 1) {
			return expressionPieceToExpression(parts[0]);
		}
		return null;
	}

	function removeFromArray(arr: Array<ExpressionParserPiece>, index: Int): Null<ExpressionParserPiece> {
		if(index >= 0 && index < arr.length) {
			return arr.splice(index, 1)[0];
		}
		return null;
	}

	function expressionPieceToExpression(piece: ExpressionParserPiece): Null<Expression> {
		switch(piece) {
			case Value(literal): return Value(literal);
			case ExpressionPlaceholder(expression): return expression;
			default: {}
		}
		return null;
	}

	function getNextOperatorIndex(): Null<Int> {
		var nextOperatorIndex = null;
		var nextOperatorPriority = -0xffff;
		for(i in 0...pieces.length) {
			final piece = pieces[i];
			final priority = getPiecePriority(piece);
			final reverse = isPieceReversePriority(piece);
			if(priority > nextOperatorPriority || (priority == nextOperatorPriority && reverse)) {
				nextOperatorIndex = i;
				nextOperatorPriority = priority;
			}
		}
		return nextOperatorIndex;
	}

	function getPiecePriority(piece: ExpressionParserPiece): Int {
		switch(piece) {
			case Prefix(op): {
				return op.priority;
			}
			case Suffix(op): {
				return op.priority;
			}
			case Infix(op): {
				return op.priority;
			}
			default: {
				return 0;
			}
		}
	}

	function isPieceReversePriority(piece: ExpressionParserPiece): Bool {
		switch(piece) {
			case Prefix(_): {
				return true;
			}
			default: {}
		}
		return false;
	}
}
/*Prefix(op: PrefixOperator);
	Value(literal: Literal);
	Suffix(op: SuffixOperator);
	Infix(op: InfixOperator);*/