// tests/templates/TemplateExecutionEngine.test.ts

import Database from "better-sqlite3";
import fs from "fs";
import path from "path";
import Decimal from "decimal.js";

import { JournalEngine } from "../../src/application/JournalEngine";
import { SqliteAccountRepository } from "../../src/infrastructure/sqlite/SqliteAccountRepository";
import { SqliteJournalRepository } from "../../src/infrastructure/sqlite/SqliteJournalRepository";

import { TemplateRegistry } from "../../src/templates/registry/TemplateRegistry";
import { TemplateExecutionEngine } from "../../src/templates/TemplateExecutionEngine";
import { PostActionRegistry } from "../../src/templates/ports/PostActionPort";
import { InventoryCostingPort } from "../../src/templates/ports/InventoryCostingPort";
import { ExchangeRateProviderPort } from "../../src/templates/ports/ExchangeRateProviderPort";

import purchaseCashTemplate from "../../src/templates/fixtures/purchase_cash.json";
import saleCashTemplate from "../../src/templates/fixtures/sale_cash.json";
import inventoryDamageTemplate from "../../src/templates/fixtures/inventory_damage.json";
import openingBalanceTemplate from "../../src/templates/fixtures/opening_balance_simple.json";
import { TemplateDefinition } from "../../src/templates/types/TemplateDefinition";

// ===== بدائل اختبار (Test Doubles) للمنافذ الخارجية =====
class FakeInventoryCostingPort implements InventoryCostingPort {
  async calculateCogs(): Promise<Decimal> { return new Decimal(29000); }
  calculateItemsRevenueSum(): Decimal { return new Decimal(0); }
}
class FakeExchangeRateProvider implements ExchangeRateProviderPort {
  async getRate(): Promise<string> { return "135.5"; }
}

describe("TemplateExecutionEngine - اختبارات تكامل شاملة عبر المحرك الفعلي", () => {
  let db: Database.Database;
  let engine: TemplateExecutionEngine;
  const TENANT_ID = "tenant-001";

  beforeEach(() => {
    db = new Database(":memory:");
    const schema = fs.readFileSync(
      path.join(__dirname, "../../src/infrastructure/sqlite/schema.sql"), "utf-8"
    );
    db.exec(schema);

    const insertAccount = db.prepare(`
      INSERT INTO accounts (id, tenant_id, code, name_ar_simple, account_type, normal_balance, is_header, is_postable)
      VALUES (?, ?, ?, ?, ?, ?, 0, 1)
    `);
    const accounts: Array<[string, string, string, string]> = [
      ["1101", "الصندوق الرئيسي", "asset", "debit"],
      ["1310", "مخزون البضاعة", "asset", "debit"],
      ["2110", "الموردون", "liability", "credit"],
      ["1230", "ذمم مدينة أخرى", "asset", "debit"],
      ["4150", "إيرادات المبيعات", "revenue", "credit"],
      ["5110", "تكلفة البضاعة المباعة", "expense", "debit"],
      ["5701", "تالف ومنتهي الصلاحية", "expense", "debit"],
      ["3100", "رأس المال", "equity", "credit"],
    ];
    accounts.forEach(([code, name, type, normal]) =>
      insertAccount.run(`acc-${code}`, TENANT_ID, code, name, type, normal)
    );

    const journalEngine = new JournalEngine(
      new SqliteAccountRepository(db),
      new SqliteJournalRepository(db)
    );

    const registry = new TemplateRegistry();
    registry.registerMany([
      purchaseCashTemplate as unknown as TemplateDefinition,
      saleCashTemplate as unknown as TemplateDefinition,
      inventoryDamageTemplate as unknown as TemplateDefinition,
      openingBalanceTemplate as TemplateDefinition,
    ]);

    engine = new TemplateExecutionEngine(
      registry, journalEngine,
      new FakeInventoryCostingPort(), new FakeExchangeRateProvider(),
      new PostActionRegistry()
    );
  });

  afterEach(() => db.close());

  it("[purchase_cash] ينتج قيدًا متوازنًا من القالب الفعلي", async () => {
    const result = await engine.execute({
      templateCode: "purchase_cash", tenantId: TENANT_ID, baseCurrencyCode: "YER",
      payload: { total_amount: "50000", paid_from_account: "1101" },
    });

    expect(result.primaryEntry.totalDebitBase().toNumber()).toBe(50000);
    expect(result.primaryEntry.lines).toHaveLength(2);
  });

  it("[sale_cash] ينتج قيدين (إيراد + تكلفة) عند الوضع التفصيلي، مرتبطين بنفس المعاملة", async () => {
    const result = await engine.execute({
      templateCode: "sale_cash", tenantId: TENANT_ID, baseCurrencyCode: "YER", warehouseId: "wh-1",
      payload: {
        inventory_mode: true,
        items: [{ item_id: "item-1", qty: 2, lineTotal: "45000" }],
        received_to_account: "1101",
      },
    });

    expect(result.primaryEntry.totalDebitBase().toNumber()).toBe(45000);
    expect(result.secondaryEntry).not.toBeNull();
    expect(result.secondaryEntry!.totalDebitBase().toNumber()).toBe(29000); // من FakeInventoryCostingPort
    expect(result.secondaryEntry!.sourceTransactionId).toBe(result.primaryEntry.sourceTransactionId);
  });

  it("[sale_cash] لا ينتج قيدًا ثانويًا في الوضع السريع (بلا أصناف)", async () => {
    const result = await engine.execute({
      templateCode: "sale_cash", tenantId: TENANT_ID, baseCurrencyCode: "YER",
      payload: { inventory_mode: false, total_amount: "10000", received_to_account: "1101" },
    });

    expect(result.secondaryEntry).toBeNull();
  });

  it("[inventory_damage] يوزّع التالف على 3 أطراف بنسب متكسرة ويبقى متوازنًا تمامًا", async () => {
    const result = await engine.execute({
      templateCode: "inventory_damage", tenantId: TENANT_ID, baseCurrencyCode: "YER",
      payload: {
        total_amount: "1000",
        distribution: [
          { target_type: "shop_loss", percentage: 33.33 },
          { target_type: "supplier", percentage: 33.33 },
          { target_type: "other_receivable", percentage: 33.34 },
        ],
      },
    });

    // التحقق الحاسم: التوازن التام رغم كسور النسب (33.33% × 3 ≠ 100% حسابيًا)
    expect(result.primaryEntry.totalDebitBase().toNumber()).toBe(1000);
    expect(result.primaryEntry.lines).toHaveLength(4); // 3 أسطر توزيع + سطر المخزون الدائن
  });

  it("[inventory_damage] Fuzz: 200 توزيع عشوائي عبر المحرك الفعلي يبقى متوازنًا دومًا", async () => {
    for (let i = 0; i < 200; i++) {
      const total = (Math.floor(Math.random() * 100000) / 100).toFixed(2);
      const p1 = Math.random() * 100;
      const p2 = Math.random() * (100 - p1);
      // النسبة الثالثة تُحسب بالمكمّل العشري الدقيق (Decimal) لتفادي أخطاء IEEE-754
      // التي تجعل sum(percentages) != 100 فيتم رفض التحقق (سلوك صحيح من المدقق).
      const p3 = new Decimal(100).minus(new Decimal(p1)).minus(new Decimal(p2)).toNumber();

      const result = await engine.execute({
        templateCode: "inventory_damage", tenantId: TENANT_ID, baseCurrencyCode: "YER",
        payload: {
          total_amount: total,
          distribution: [
            { target_type: "shop_loss", percentage: p1 },
            { target_type: "supplier", percentage: p2 },
            { target_type: "other_receivable", percentage: p3 },
          ],
        },
      });

      expect(result.primaryEntry.totalDebitBase().toNumber()).toBeCloseTo(Number(total), 2);
    }
  });

  it("[opening_balance_simple] يحسب plug_balance تلقائيًا لموازنة القيد", async () => {
    const result = await engine.execute({
      templateCode: "opening_balance_simple", tenantId: TENANT_ID, baseCurrencyCode: "YER",
      payload: { cash_balance: "75000" },
    });

    const capitalLine = result.primaryEntry.lines.find((l) => l.accountId === "acc-3100");
    expect(capitalLine!.baseAmount.toNumber()).toBe(75000);
    expect(result.primaryEntry.totalDebitBase().toNumber()).toBe(75000);
  });

  it("يرفض تنفيذ قالب بحقل مطلوب ناقص برسالة تحقق واضحة", async () => {
    await expect(
      engine.execute({
        templateCode: "purchase_cash", tenantId: TENANT_ID, baseCurrencyCode: "YER",
        payload: { paid_from_account: "1101" }, // total_amount مفقود
      })
    ).rejects.toThrow(/مطلوب/);
  });
});
