// tests/Money.test.ts

import { Money, InvalidMoneyOperationError } from "../src/domain/value-objects/Money";

describe("Money Value Object", () => {
  it("يجمع مبلغين بنفس العملة بدقة تامة دون أخطاء فاصلة عائمة", () => {
    const a = Money.fromDecimalString("0.1", "YER");
    const b = Money.fromDecimalString("0.2", "YER");
    // في JavaScript الأصلي: 0.1 + 0.2 = 0.30000000000000004 (خطأ شهير)
    expect(a.add(b).toStorageString()).toBe("0.3000");
  });

  it("يرفض الجمع بين عملتين مختلفتين", () => {
    const a = Money.fromNumber(100, "YER");
    const b = Money.fromNumber(100, "SAR");
    expect(() => a.add(b)).toThrow(InvalidMoneyOperationError);
  });

  it("يحوّل العملة بسعر الصرف بشكل صحيح", () => {
    const sar = Money.fromNumber(100, "SAR");
    const yer = sar.convertTo("YER", "135.5");
    expect(yer.toNumber()).toBe(13550);
    expect(yer.currencyCode).toBe("YER");
  });

  it("يرفض سعر صرف صفري أو سالب", () => {
    const sar = Money.fromNumber(100, "SAR");
    expect(() => sar.convertTo("YER", 0)).toThrow(InvalidMoneyOperationError);
    expect(() => sar.convertTo("YER", -5)).toThrow(InvalidMoneyOperationError);
  });

  it("يجمع مصفوفة مبالغ عبر Money.sum", () => {
    const amounts = [
      Money.fromNumber(100, "YER"),
      Money.fromNumber(250.5, "YER"),
      Money.fromNumber(49.5, "YER"),
    ];
    expect(Money.sum(amounts, "YER").toNumber()).toBe(400);
  });
});
