// src/templates/engine/ExpressionEngine.ts

import Decimal from "decimal.js";
import { AstNode, Parser, PathSegment } from "./Parser";
import { FunctionRegistry } from "./FunctionRegistry";
import { ExpressionEvaluationError } from "./errors";

/**
 * أنواع القيم المقبولة. يُستخدم `unknown` بدل `number` صراحةً لأن:
 * 1) قيم JSON القادمة من واجهات الإدخال تكون أرقامًا JS عادية (number).
 * 2) المصفوفات داخل payload غير معروفة البنية مسبقًا، والـ collect ([]) يعيد مصفوفات قيم خام.
 */
export type ExprValue = Decimal | string | boolean | number | null | unknown[];

export interface ExpressionContext {
  /** بيانات الحقول الخام المُدخَلة من المستخدم، بالإضافة لأي نطاقات مُحقَنة مثل job/tenant */
  fields: Record<string, unknown>;
  /** فهرس حلقة التكرار الحالية عند معالجة repeat_for، غير موجود خارج هذا السياق */
  loopIndex?: number;
  /** قيم محسوبة مسبقًا بشكل غير متزامن (تكلفة المخزون، إجمالي الأصناف...) */
  computed: Record<string, Decimal | string>;
}

/** يحذف أقواس {{ }} الزخرفية فقط (اتفاقية التصميم المعتمدة في القسم 0.2) */
function stripBraces(expr: string): string {
  return expr.replace(/\{\{/g, "").replace(/\}\}/g, "");
}

export class ExpressionEngine {
  private static readonly functionRegistry = new FunctionRegistry();

  /** يقيِّم صيغة ويعيد القيمة الخام كما هي دون إجبار نوع معيّن */
  static evaluateRaw(expr: string, context: ExpressionContext): ExprValue {
    const ast = Parser.parse(stripBraces(expr));
    return this.evalNode(ast, context);
  }

  static evaluateAsDecimal(expr: string, context: ExpressionContext): Decimal {
    return this.toDecimal(this.evaluateRaw(expr, context));
  }

  static evaluateAsString(expr: string, context: ExpressionContext): string {
    return this.toStringValue(this.evaluateRaw(expr, context));
  }

  static evaluateAsBoolean(expr: string, context: ExpressionContext): boolean {
    return this.toBoolean(this.evaluateRaw(expr, context));
  }

  // ===================== المُقيِّم الداخلي =====================

  private static evalNode(node: AstNode, context: ExpressionContext): ExprValue {
    switch (node.type) {
      case "Number": return new Decimal(node.value);
      case "String": return node.value;
      case "Bool": return node.value;
      case "Null": return null;

      case "Path":
        return this.resolvePath(context.fields, node.segments, context.loopIndex);

      case "Call": {
        const args = node.args.map((a) => this.evalNode(a, context));
        return this.functionRegistry.call(node.name, args, context);
      }

      case "Unary": {
        const operand = this.evalNode(node.operand, context);
        if (node.op === "!") return !this.toBoolean(operand);
        return this.toDecimal(operand).negated();
      }

      case "Binary":
        return this.evalBinary(node.op, node.left, node.right, context);
    }
  }

  private static evalBinary(
    op: string,
    leftNode: AstNode,
    rightNode: AstNode,
    context: ExpressionContext
  ): ExprValue {
    // التقييم الكسول (Short-circuit) للعوامل المنطقية
    if (op === "&&") {
      return this.toBoolean(this.evalNode(leftNode, context)) &&
             this.toBoolean(this.evalNode(rightNode, context));
    }
    if (op === "||") {
      return this.toBoolean(this.evalNode(leftNode, context)) ||
             this.toBoolean(this.evalNode(rightNode, context));
    }

    const left = this.evalNode(leftNode, context);
    const right = this.evalNode(rightNode, context);

    switch (op) {
      case "+": return this.toDecimal(left).plus(this.toDecimal(right));
      case "-": return this.toDecimal(left).minus(this.toDecimal(right));
      case "*": return this.toDecimal(left).times(this.toDecimal(right));
      case "/": return this.toDecimal(left).dividedBy(this.toDecimal(right));
      case "<": return this.toDecimal(left).lessThan(this.toDecimal(right));
      case ">": return this.toDecimal(left).greaterThan(this.toDecimal(right));
      case "<=": return this.toDecimal(left).lessThanOrEqualTo(this.toDecimal(right));
      case ">=": return this.toDecimal(left).greaterThanOrEqualTo(this.toDecimal(right));
      case "==": return this.looseEquals(left, right);
      case "!=": return !this.looseEquals(left, right);
      default:
        throw new ExpressionEvaluationError(`عامل غير مدعوم: "${op}"`);
    }
  }

  private static looseEquals(a: ExprValue, b: ExprValue): boolean {
    if (a === null || b === null) return a === b;
    if (a instanceof Decimal && this.isNumericLike(b)) return a.equals(this.toDecimal(b));
    if (b instanceof Decimal && this.isNumericLike(a)) return this.toDecimal(a).equals(b);
    if (typeof a === "boolean" || typeof b === "boolean") return this.toBoolean(a) === this.toBoolean(b);
    return String(a) === String(b);
  }

  private static isNumericLike(v: ExprValue): boolean {
    return v instanceof Decimal || typeof v === "number" ||
      (typeof v === "string" && v.trim() !== "" && !isNaN(Number(v)));
  }

  /**
   * حلّ مسار مثل: distribution[i].percentage أو distribution[].percentage أو customers[2].amount
   * نمط collect ([]) يُطبَّق على باقي المسار على كل عنصر في المصفوفة ويُعيد مصفوفة نتائج.
   */
  private static resolvePath(
    root: unknown,
    segments: PathSegment[],
    loopIndex: number | undefined
  ): ExprValue {
    return this.resolveSegments(root, segments, loopIndex) as ExprValue;
  }

  private static resolveSegments(
    value: unknown,
    segments: PathSegment[],
    loopIndex: number | undefined
  ): unknown {
    if (segments.length === 0) return value;
    const [seg, ...rest] = segments as [PathSegment, ...PathSegment[]];

    if (seg.kind === "prop") {
      const next = value == null ? undefined : (value as Record<string, unknown>)[seg.name];
      return this.resolveSegments(next, rest, loopIndex);
    }

    if (seg.kind === "index") {
      if (!Array.isArray(value)) {
        throw new ExpressionEvaluationError(`استُخدم [${seg.value}] على قيمة ليست مصفوفة`);
      }
      return this.resolveSegments(value[seg.value], rest, loopIndex);
    }

    if (seg.kind === "indexVar") {
      if (loopIndex === undefined) {
        throw new ExpressionEvaluationError('استُخدم [i] خارج سياق تكرار (repeat_for)');
      }
      if (!Array.isArray(value)) {
        throw new ExpressionEvaluationError("استُخدم [i] على قيمة ليست مصفوفة");
      }
      return this.resolveSegments(value[loopIndex], rest, loopIndex);
    }

    // collect: [] - يُطبَّق باقي المسار على كل عنصر، يُعيد مصفوفة
    if (!Array.isArray(value)) {
      throw new ExpressionEvaluationError("استُخدم [] على قيمة ليست مصفوفة");
    }
    return value.map((item) => this.resolveSegments(item, rest, loopIndex));
  }

  // ===================== دوال التحويل (Coercion Helpers) =====================

  static toDecimal(value: ExprValue): Decimal {
    if (value instanceof Decimal) return value;
    if (typeof value === "number" && Number.isFinite(value)) {
      return new Decimal(value);
    }
    if (typeof value === "string" && value.trim() !== "" && !isNaN(Number(value))) {
      return new Decimal(value);
    }
    if (value === null || value === undefined) return new Decimal(0);
    throw new ExpressionEvaluationError(`لا يمكن تحويل القيمة إلى رقم: ${JSON.stringify(value)}`);
  }

  static toStringValue(value: ExprValue): string {
    if (typeof value === "string") return value;
    if (value instanceof Decimal) return value.toString();
    if (typeof value === "boolean") return String(value);
    throw new ExpressionEvaluationError(`القيمة فارغة أو غير صالحة كمرجع نصي: ${JSON.stringify(value)}`);
  }

  static toBoolean(value: ExprValue): boolean {
    if (typeof value === "boolean") return value;
    if (value === null || value === undefined) return false;
    if (value instanceof Decimal) return !value.isZero();
    if (typeof value === "string") return value.length > 0;
    if (Array.isArray(value)) return value.length > 0;
    return Boolean(value);
  }
}
