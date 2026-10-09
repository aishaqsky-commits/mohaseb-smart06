// src/templates/engine/FunctionRegistry.ts

import Decimal from "decimal.js";
import { ExprValue, ExpressionContext } from "./ExpressionEngine";
import { ExpressionEvaluationError, UnknownFunctionError } from "./errors";

type FunctionImpl = (args: ExprValue[], context: ExpressionContext) => ExprValue;

function toDecimalStrict(value: ExprValue, fnName: string, argIndex: number): Decimal {
  if (value instanceof Decimal) return value;
  if (typeof value === "number") return new Decimal(value);
  if (typeof value === "string" && value.trim() !== "" && !isNaN(Number(value))) {
    return new Decimal(value);
  }
  throw new ExpressionEvaluationError(
    `الدالة "${fnName}": المعطى رقم ${argIndex + 1} ليس رقمًا صالحًا`
  );
}

/** خريطة توزيع التالف - ثابتة ومطابقة لشجرة الحسابات المصمَّمة سابقًا */
const DAMAGE_TARGET_ACCOUNT_MAP: Record<string, string> = {
  shop_loss: "5701",
  supplier: "2110",
  other_receivable: "1230",
};

/**
 * سجل الدوال المغلق (Whitelist) - هذه القائمة فقط هي ما يمكن استدعاؤه من أي قالب.
 * إضافة دالة جديدة تتطلب تعديل هذا الملف صراحة (لا امتداد ديناميكي من القوالب نفسها).
 */
export class FunctionRegistry {
  private readonly functions = new Map<string, FunctionImpl>();

  constructor() {
    this.registerBuiltins();
  }

  private register(name: string, impl: FunctionImpl): void {
    this.functions.set(name, impl);
  }

  call(name: string, args: ExprValue[], context: ExpressionContext): ExprValue {
    const fn = this.functions.get(name);
    if (!fn) throw new UnknownFunctionError(name);
    return fn(args, context);
  }

  private registerBuiltins(): void {
    this.register("remaining", (args) => {
      const total = toDecimalStrict(args[0], "remaining", 0);
      const paid = toDecimalStrict(args[1], "remaining", 1);
      return total.minus(paid);
    });

    this.register("apportion", (args) => {
      const total = toDecimalStrict(args[0], "apportion", 0);
      const percentage = toDecimalStrict(args[1], "apportion", 1);
      return total.times(percentage).dividedBy(100);
    });

    this.register("sum", (args) => {
      const arr = args[0];
      if (!Array.isArray(arr)) {
        throw new ExpressionEvaluationError('الدالة "sum" تتطلب مصفوفة كمعطى (استخدم نمط [] في المسار)');
      }
      return arr.reduce(
        (acc: Decimal, v) => acc.plus(toDecimalStrict(v, "sum", 0)),
        new Decimal(0)
      );
    });

    this.register("map_target_to_account", (args) => {
      const targetType = String(args[0]);
      const accountCode = DAMAGE_TARGET_ACCOUNT_MAP[targetType];
      if (!accountCode) {
        throw new ExpressionEvaluationError(`نوع جهة توزيع غير معروف: "${targetType}"`);
      }
      return accountCode;
    });

    /** القيم المحسوبة مسبقًا (Async) تُحقَن في context.computed قبل التقييم - انظر TemplateExecutionEngine */
    this.register("cogs_amount", (_args, context) => this.readComputed(context, "cogs_amount"));
    this.register("total_or_items_sum", (_args, context) => this.readComputed(context, "total_or_items_sum"));
    this.register("items_cost_sum", (_args, context) => this.readComputed(context, "cogs_amount"));
  }

  private readComputed(context: ExpressionContext, key: string): Decimal {
    const value = context.computed[key];
    if (value === undefined) {
      throw new ExpressionEvaluationError(
        `القيمة المحسوبة "${key}" غير متوفرة - تأكد من حسابها مسبقًا قبل تنفيذ القالب`
      );
    }
    return value instanceof Decimal ? value : new Decimal(value);
  }
}
