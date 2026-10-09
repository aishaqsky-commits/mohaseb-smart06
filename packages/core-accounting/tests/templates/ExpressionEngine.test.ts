// tests/templates/ExpressionEngine.test.ts

import Decimal from "decimal.js";
import { ExpressionEngine, ExpressionContext } from "../../src/templates/engine/ExpressionEngine";

function ctx(fields: Record<string, unknown>, computed: Record<string, Decimal> = {}): ExpressionContext {
  return { fields, computed };
}

describe("ExpressionEngine", () => {
  it("يحسب صيغة حسابية بسيطة بعد حذف أقواس {{}}", () => {
    const result = ExpressionEngine.evaluateAsDecimal("{{total_amount}}", ctx({ total_amount: "15000" }));
    expect(result.toNumber()).toBe(15000);
  });

  it("يستدعي دالة remaining بشكل صحيح", () => {
    const result = ExpressionEngine.evaluateAsDecimal(
      "remaining({{total_amount}},{{paid_amount}})",
      ctx({ total_amount: "15000", paid_amount: "5000" })
    );
    expect(result.toNumber()).toBe(10000);
  });

  it("يحسب apportion بنسبة مئوية بدقة عشرية", () => {
    const result = ExpressionEngine.evaluateAsDecimal(
      "apportion({{total}}, {{pct}})",
      ctx({ total: "1000", pct: "33.33" })
    );
    expect(result.toNumber()).toBeCloseTo(333.3, 4);
  });

  it("يقيّم شرطًا منطقيًا بسيطًا (بلا أقواس {{}})", () => {
    expect(ExpressionEngine.evaluateAsBoolean("inventory_mode == true", ctx({ inventory_mode: true }))).toBe(true);
    expect(ExpressionEngine.evaluateAsBoolean("pay_now == false", ctx({ pay_now: true }))).toBe(false);
  });

  it("يقيّم شرط != null بشكل صحيح", () => {
    expect(ExpressionEngine.evaluateAsBoolean("ref != null", ctx({ ref: "abc" }))).toBe(true);
    expect(ExpressionEngine.evaluateAsBoolean("ref != null", ctx({ ref: null }))).toBe(false);
  });

  it("يدعم عوامل المقارنة المركّبة", () => {
    expect(
      ExpressionEngine.evaluateAsBoolean("paid_amount <= total_amount", ctx({ paid_amount: "500", total_amount: "1000" }))
    ).toBe(true);
    expect(
      ExpressionEngine.evaluateAsBoolean("paid_amount <= total_amount", ctx({ paid_amount: "1500", total_amount: "1000" }))
    ).toBe(false);
  });

  it("يحلّ مسار [i] داخل سياق تكرار", () => {
    const context: ExpressionContext = {
      fields: { distribution: [{ percentage: 30 }, { percentage: 70 }] },
      computed: {},
      loopIndex: 1,
    };
    const result = ExpressionEngine.evaluateAsDecimal("{{distribution[i].percentage}}", context);
    expect(result.toNumber()).toBe(70);
  });

  it("يحلّ نمط [] (collect) ويحسب sum()", () => {
    const context = ctx({ distribution: [{ percentage: 40 }, { percentage: 60 }] });
    const result = ExpressionEngine.evaluateAsDecimal("sum(distribution[].percentage)", context);
    expect(result.toNumber()).toBe(100);
  });

  it("يرفض استخدام [i] خارج سياق تكرار برسالة عربية واضحة", () => {
    expect(() =>
      ExpressionEngine.evaluateAsDecimal("{{distribution[i].percentage}}", ctx({ distribution: [] }))
    ).toThrow(/خارج سياق تكرار/);
  });

  it("يستدعي map_target_to_account ويعيد كود الحساب الصحيح", () => {
    const result = ExpressionEngine.evaluateAsString(
      "map_target_to_account({{target_type}})",
      ctx({ target_type: "supplier" })
    );
    expect(result).toBe("2110");
  });

  it("يقرأ القيم المحسوبة مسبقًا عبر cogs_amount()", () => {
    const result = ExpressionEngine.evaluateAsDecimal(
      "cogs_amount()",
      ctx({}, { cogs_amount: new Decimal(29000) })
    );
    expect(result.toNumber()).toBe(29000);
  });

  it("يرفض دالة غير معروفة (حماية القائمة البيضاء)", () => {
    expect(() =>
      ExpressionEngine.evaluateAsDecimal("eval_system_command()", ctx({}))
    ).toThrow(/غير معروفة/);
  });

  it("يرفض محرفًا غير متوقع في الصيغة (حماية من الحقن)", () => {
    expect(() =>
      ExpressionEngine.evaluateAsDecimal("total_amount; DROP TABLE accounts", ctx({ total_amount: "100" }))
    ).toThrow();
  });
});
