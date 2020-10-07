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
import parsers.expr.Position;

enum ExpressionParserMode {
	Prefix;
	Value;
	Suffix;
	Infix;
}

enum ExpressionParserPiece {
	Prefix(op: PrefixOperator, pos: Position);
	Value(literal: Literal, pos: Position);
	Suffix(op: SuffixOperator, pos: Position);
	Infix(op: InfixOperator, pos: Position);
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
				case Prefix(op, pos): trace(op.op);
				case Value(str, pos): trace(str);
				case Suffix(op, pos): trace(op.op);
				case Infix(op, pos): trace(op.op);
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
		var cancelThreshold = 0;
		while(parser.getIndex() < parser.getContent().length) {
			parser.parseWhitespaceOrComments();
			var oldIndex = parser.getIndex();
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

			if(oldIndex == parser.getIndex()) {
				cancelThreshold++;
				if(++cancelThreshold > 10) {
					break;
				}
			} else {
				cancelThreshold = 0;
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
		final startIndex = parser.getIndex();
		final op = checkForOperators(cast PrefixOperators.all());
		if(op != null) {
			pieces.push(ExpressionParserPiece.Prefix(cast op, parser.makePosition(startIndex)));
			parser.incrementIndex(op.op.length);
			return true;
		}
		return false;
	}

	function parseValue(): Bool {
		final startIndex = parser.getIndex();
		final literal = parser.parseNextLiteral();
		if(literal != null) {
			pieces.push(ExpressionParserPiece.Value(literal, parser.makePosition(startIndex)));
			return true;
		}
		return false;
	}

	function parseSuffix(): Bool {
		final startIndex = parser.getIndex();
		final op = checkForOperators(cast SuffixOperators.all());
		if(op != null) {
			pieces.push(ExpressionParserPiece.Suffix(cast op, parser.makePosition(startIndex)));
			parser.incrementIndex(op.op.length);
			return true;
		}
		return false;
	}

	function parseInfix(): Bool {
		final startIndex = parser.getIndex();
		final op = checkForOperators(cast InfixOperators.all());
		if(op != null) {
			pieces.push(ExpressionParserPiece.Infix(cast op, parser.makePosition(startIndex)));
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
		var errorThreshold = 0;
		while(parts.length > 1) {
			final currSize = parts.length;
			final index = getNextOperatorIndex(parts);
			if(index != null) {
				final removedPiece = removeFromArray(parts, index);
				if(removedPiece == null) {
					error = true;
					break;
				}
				switch(removedPiece) {
					case Prefix(op, pos): {
						final piece = removeFromArray(parts, index);
						if(piece != null) {
							final expr = expressionPieceToExpression(piece);
							if(expr != null) {
								parts.insert(index, ExpressionPlaceholder(Prefix(op, expr, pos)));
							} else {
								error = true;
								break;
							}
						} else {
							error = true;
							break;
						}
					}
					case Suffix(op, pos): {
						final piece = removeFromArray(parts, index - 1);
						if(piece != null) {
							final expr = expressionPieceToExpression(piece);
							if(expr != null) {
								parts.insert(index, ExpressionPlaceholder(Suffix(op, expr, pos)));
							} else {
								error = true;
								break;
							}
						} else {
							error = true;
							break;
						}
					}
					case Infix(op, pos): {
						final lpiece = removeFromArray(parts, index - 1);
						final rpiece = removeFromArray(parts, index - 1);
						if(lpiece != null && rpiece != null) {
							final lexpr = expressionPieceToExpression(lpiece);
							final rexpr = expressionPieceToExpression(rpiece);
							if(lexpr != null && rexpr != null) {
								parts.insert(index - 1, ExpressionPlaceholder(Infix(op, lexpr, rexpr, pos)));
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

			if(currSize == parts.length) {
				if(++errorThreshold > 10) {
					error = true;
					break;
				} else {
					errorThreshold = 0;
				}
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
			case Value(literal, pos): return Value(literal, pos);
			case ExpressionPlaceholder(expression): return expression;
			default: {}
		}
		return null;
	}

	function getNextOperatorIndex(parts: Array<ExpressionParserPiece>): Null<Int> {
		var nextOperatorIndex: Null<Int> = null;
		var nextOperatorPriority = -0xffff;
		for(i in 0...parts.length) {
			final piece = parts[i];
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
			case Prefix(op, pos): {
				return op.priority;
			}
			case Suffix(op, pos): {
				return op.priority;
			}
			case Infix(op, pos): {
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
