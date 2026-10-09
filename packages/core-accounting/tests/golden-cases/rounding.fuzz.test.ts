// tests/golden-cases/rounding.fuzz.test.ts

import { Money } from "../../src/domain/value-objects/Money";

/**
 * يطبّق "قاعدة التقريب الإلزامية" المصممة سابقًا لقوالب التوزيع (التالف، الرصيد الافتتاحي):
 * السطر الأخير = الإجمالي - مجموع كل الأسطر السابقة (لا قسمة مباشرة مطلقًا).
 */
function distributeWithLastLineRounding(
  total: Money,
  percentages: number[]
): Money[] {
  const results: Money[] = [];
  let runningSum = Money.zero(total.currencyCode);

  for (let i = 0; i < percentages.length; i++) {
    if (i === percentages.length - 1) {
      // السطر الأخير: الباقي بالضبط، لا تقريب مستقل
      results.push(total.subtract(runningSum));
    } else {
      const share = total.multiply(percentages[i]! / 100);
      // تقريب لأقرب وحدة عرض (محاكاة نفس سلوك Money.toStorageString)
      const rounded = Money.fromDecimalString(share.toStorageString(), total.currencyCode);
      results.push(rounded);
      runningSum = runningSum.add(rounded);
    }
  }
  return results;
}

describe("قاعدة التقريب الإلزامية - اختبار Fuzz", () => {
  it("توزيع 1000 على 3 أطراف بنسب 33.33% يبقى متوازنًا دومًا", () => {
    const total = Money.fromNumber(1000, "YER");
    const parts = distributeWithLastLineRounding(total, [33.33, 33.33, 33.34]);

    const sum = Money.sum(parts, "YER");
    expect(sum.equals(total)).toBe(true); // يجب أن يتطابق تمامًا دون أي فرق
  });

  it("Fuzz: 500 توزيع عشوائي مختلف يبقى متوازنًا 100% من المرات", () => {
    for (let i = 0; i < 500; i++) {
      const totalValue = Math.floor(Math.random() * 1000000) / 100;
      const total = Money.fromNumber(totalValue, "YER");

      const numParts = 2 + Math.floor(Math.random() * 4);
      const rawPercentages = Array.from({ length: numParts }, () => Math.random());
      const sumRaw = rawPercentages.reduce((a, b) => a + b, 0);
      const percentages = rawPercentages.map((p) => (p / sumRaw) * 100);

      const parts = distributeWithLastLineRounding(total, percentages);
      const sum = Money.sum(parts, "YER");

      expect(sum.equals(total)).toBe(true);
    }
  });
});
