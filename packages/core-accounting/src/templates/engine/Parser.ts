// src/templates/engine/Parser.ts

import { Token, TokenType, Lexer } from "./Lexer";
import { ExpressionSyntaxError } from "./errors";

export type PathSegment =
  | { kind: "prop"; name: string }
  | { kind: "index"; value: number }
  | { kind: "indexVar" }   // [i] - فهرس حلقة التكرار الحالية
  | { kind: "collect" };    // [] - جمع كل عناصر المصفوفة

export type AstNode =
  | { type: "Number"; value: string }
  | { type: "String"; value: string }
  | { type: "Bool"; value: boolean }
  | { type: "Null" }
  | { type: "Path"; segments: PathSegment[] }
  | { type: "Call"; name: string; args: AstNode[] }
  | { type: "Unary"; op: "!" | "-"; operand: AstNode }
  | { type: "Binary"; op: string; left: AstNode; right: AstNode };

/**
 * محلِّل تنازلي تكراري (Recursive Descent Parser) بترتيب أولوية ثابت:
 * || ثم && ثم == != ثم < > <= >= ثم + - ثم * / ثم unary ثم primary
 */
export class Parser {
  private tokens: Token[];
  private pos = 0;

  constructor(source: string) {
    this.tokens = new Lexer(source).tokenize();
  }

  static parse(source: string): AstNode {
    const parser = new Parser(source);
    const node = parser.parseExpression();
    parser.expect("EOF");
    return node;
  }

  private current(): Token { return this.tokens[this.pos]!; }

  private expect(type: TokenType): Token {
    const tok = this.current();
    if (tok.type !== type) {
      throw new ExpressionSyntaxError(`متوقَّع ${type} لكن وُجد ${tok.type} ("${tok.value}")`, tok.position);
    }
    this.pos++;
    return tok;
  }

  private matchOp(...ops: string[]): boolean {
    const tok = this.current();
    if (tok.type === "OP" && ops.includes(tok.value)) {
      this.pos++;
      return true;
    }
    return false;
  }

  private lastConsumedOp(): string {
    return this.tokens[this.pos - 1]!.value;
  }

  parseExpression(): AstNode { return this.parseLogicalOr(); }

  private parseLogicalOr(): AstNode {
    let left = this.parseLogicalAnd();
    while (this.matchOp("||")) {
      const op = this.lastConsumedOp();
      left = { type: "Binary", op, left, right: this.parseLogicalAnd() };
    }
    return left;
  }

  private parseLogicalAnd(): AstNode {
    let left = this.parseEquality();
    while (this.matchOp("&&")) {
      const op = this.lastConsumedOp();
      left = { type: "Binary", op, left, right: this.parseEquality() };
    }
    return left;
  }

  private parseEquality(): AstNode {
    let left = this.parseComparison();
    while (this.matchOp("==", "!=")) {
      const op = this.lastConsumedOp();
      left = { type: "Binary", op, left, right: this.parseComparison() };
    }
    return left;
  }

  private parseComparison(): AstNode {
    let left = this.parseAdditive();
    while (this.matchOp("<", ">", "<=", ">=")) {
      const op = this.lastConsumedOp();
      left = { type: "Binary", op, left, right: this.parseAdditive() };
    }
    return left;
  }

  private parseAdditive(): AstNode {
    let left = this.parseMultiplicative();
    while (this.matchOp("+", "-")) {
      const op = this.lastConsumedOp();
      left = { type: "Binary", op, left, right: this.parseMultiplicative() };
    }
    return left;
  }

  private parseMultiplicative(): AstNode {
    let left = this.parseUnary();
    while (this.matchOp("*", "/")) {
      const op = this.lastConsumedOp();
      left = { type: "Binary", op, left, right: this.parseUnary() };
    }
    return left;
  }

  private parseUnary(): AstNode {
    if (this.matchOp("!", "-")) {
      const op = this.lastConsumedOp() as "!" | "-";
      return { type: "Unary", op, operand: this.parseUnary() };
    }
    return this.parsePrimary();
  }

  private parsePrimary(): AstNode {
    const tok = this.current();

    if (tok.type === "NUMBER") { this.pos++; return { type: "Number", value: tok.value }; }
    if (tok.type === "STRING") { this.pos++; return { type: "String", value: tok.value }; }
    if (tok.type === "BOOL") { this.pos++; return { type: "Bool", value: tok.value === "true" }; }
    if (tok.type === "NULL") { this.pos++; return { type: "Null" }; }

    if (tok.type === "LPAREN") {
      this.pos++;
      const expr = this.parseExpression();
      this.expect("RPAREN");
      return expr;
    }

    if (tok.type === "IDENT") {
      const name = tok.value;
      this.pos++;

      // نداء دالة: identifier مباشرة متبوع بقوس فتح
      if (this.current().type === "LPAREN") {
        this.pos++;
        const args: AstNode[] = [];
        if (this.current().type !== "RPAREN") {
          args.push(this.parseExpression());
          while (this.current().type === "COMMA") {
            this.pos++;
            args.push(this.parseExpression());
          }
        }
        this.expect("RPAREN");
        return { type: "Call", name, args };
      }

      // مسار (Path): identifier متبوع اختياريًا بسلسلة .prop أو [index]
      const segments: PathSegment[] = [{ kind: "prop", name }];
      this.parsePathSuffixes(segments);
      return { type: "Path", segments };
    }

    throw new ExpressionSyntaxError(`رمز غير متوقَّع "${tok.value}"`, tok.position);
  }

  private parsePathSuffixes(segments: PathSegment[]): void {
    while (true) {
      if (this.current().type === "DOT") {
        this.pos++;
        const propTok = this.expect("IDENT");
        segments.push({ kind: "prop", name: propTok.value });
        continue;
      }
      if (this.current().type === "LBRACKET") {
        this.pos++;
        const inner = this.current();

        if (inner.type === "RBRACKET") {
          segments.push({ kind: "collect" });
          this.pos++;
        } else if (inner.type === "NUMBER") {
          segments.push({ kind: "index", value: Number(inner.value) });
          this.pos++;
          this.expect("RBRACKET");
        } else if (inner.type === "IDENT" && inner.value === "i") {
          segments.push({ kind: "indexVar" });
          this.pos++;
          this.expect("RBRACKET");
        } else {
          throw new ExpressionSyntaxError(`محتوى غير صالح داخل []: "${inner.value}"`, inner.position);
        }
        continue;
      }
      break;
    }
  }
}
