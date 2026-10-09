// tests/JournalEngine.test.ts

import Database from "better-sqlite3";
import fs from "fs";
import path from "path";
import { JournalEngine } from "../src/application/JournalEngine";
import { SqliteAccountRepository } from "../src/infrastructure/sqlite/SqliteAccountRepository";
import { SqliteJournalRepository } from "../src/infrastructure/sqlite/SqliteJournalRepository";
import {
  UnbalancedJournalEntryError,
  FiscalPeriodClosedError,
} from "../src/domain/errors/AccountingErrors";

describe("JournalEngine - اختبارات التكامل الكاملة", () => {
  let db: Database.Database;
  let engine: JournalEngine;
  const TENANT_ID = "tenant-test-001";

  beforeEach(() => {
    db = new Database(":memory:"); // قاعدة بيانات في الذاكرة لكل اختبار - عزل تام
    const schema = fs.readFileSync(
      path.join(__dirname, "../src/infrastructure/sqlite/schema.sql"),
      "utf-8"
    );
    db.exec(schema);

    // زرع حسابات اختبارية (مطابقة لـ core.seed.json المصمَّم سابقًا)
    const insertAccount = db.prepare(`
      INSERT INTO accounts (id, tenant_id, code, name_ar_simple, account_type, normal_balance, is_header, is_postable)
      VALUES (?, ?, ?, ?, ?, ?, 0, 1)
    `);
    insertAccount.run("acc-1101", TENANT_ID, "1101", "الصندوق الرئيسي", "asset", "debit");
    insertAccount.run("acc-1310", TENANT_ID, "1310", "مخزون البضاعة", "asset", "debit");
    insertAccount.run("acc-1210", TENANT_ID, "1210", "العملاء", "asset", "debit");
    insertAccount.run("acc-2110", TENANT_ID, "2110", "الموردون", "liability", "credit");
    insertAccount.run("acc-4150", TENANT_ID, "4150", "إيرادات المبيعات", "revenue", "credit");

    const accountRepo = new SqliteAccountRepository(db);
    const journalRepo = new SqliteJournalRepository(db);
    engine = new JournalEngine(accountRepo, journalRepo);
  });

  afterEach(() => db.close());

  // ===== Golden Test Case: purchase_cash من ملف القالب =====
  it("[purchase_cash] ينتج قيدًا متوازنًا: مخزون مدين / صندوق دائن", async () => {
    const entry = await engine.postEntry({
      tenantId: TENANT_ID,
      entryDate: new Date("2025-01-15"),
      descriptionSimple: "اشتريت بضاعة نقدًا",
      sourceType: "purchase",
      baseCurrencyCode: "YER",
      lines: [
        {
          accountCode: "1310", side: "debit", amount: "50000",
          currencyCode: "YER", exchangeRateUsed: "1",
        },
        {
          accountCode: "1101", side: "credit", amount: "50000",
          currencyCode: "YER", exchangeRateUsed: "1",
        },
      ],
    });

    expect(entry.totalDebitBase().toNumber()).toBe(50000);
    expect(entry.lines).toHaveLength(2);
  });

  // ===== Golden Test Case: sale_partial (دفع جزئي + رصيد عميل) =====
  it("[sale_partial] يوزّع المبلغ بين النقد والعميل بتوازن تام", async () => {
    const totalAmount = 15000;
    const receivedAmount = 5000;
    const remaining = totalAmount - receivedAmount;

    const entry = await engine.postEntry({
      tenantId: TENANT_ID,
      entryDate: new Date("2025-01-15"),
      descriptionSimple: "بيع جزئي للعميل أحمد",
      sourceType: "sale",
      baseCurrencyCode: "YER",
      lines: [
        { accountCode: "1101", side: "debit", amount: String(receivedAmount), currencyCode: "YER", exchangeRateUsed: "1" },
        { accountCode: "1210", side: "debit", amount: String(remaining), currencyCode: "YER", exchangeRateUsed: "1", contactId: "customer-ahmed" },
        { accountCode: "4150", side: "credit", amount: String(totalAmount), currencyCode: "YER", exchangeRateUsed: "1" },
      ],
    });

    expect(entry.totalDebitBase().toNumber()).toBe(totalAmount);
  });

  // ===== اختبار رفض قيد غير متوازن (خط الدفاع الأهم) =====
  it("يرفض أي قيد غير متوازن برسالة واضحة", async () => {
    await expect(
      engine.postEntry({
        tenantId: TENANT_ID,
        entryDate: new Date("2025-01-15"),
        descriptionSimple: "محاولة قيد خاطئ",
        sourceType: "manual",
        baseCurrencyCode: "YER",
        lines: [
          { accountCode: "1101", side: "debit", amount: "1000", currencyCode: "YER", exchangeRateUsed: "1" },
          { accountCode: "4150", side: "credit", amount: "999", currencyCode: "YER", exchangeRateUsed: "1" },
        ],
      })
    ).rejects.toThrow(UnbalancedJournalEntryError);
  });

  // ===== اختبار متعدد العملات (جوهري للسوق اليمني) =====
  it("يرحّل قيدًا بعملة SAR محوّلة بشكل صحيح لعملة الأساس YER", async () => {
    // شراء بـ 100 ريال سعودي بسعر صرف 135.5
    const entry = await engine.postEntry({
      tenantId: TENANT_ID,
      entryDate: new Date("2025-01-15"),
      descriptionSimple: "شراء بالريال السعودي",
      sourceType: "purchase",
      baseCurrencyCode: "YER",
      lines: [
        { accountCode: "1310", side: "debit", amount: "100", currencyCode: "SAR", exchangeRateUsed: "135.5" },
        { accountCode: "1101", side: "credit", amount: "13550", currencyCode: "YER", exchangeRateUsed: "1" },
      ],
    });

    expect(entry.totalDebitBase().toNumber()).toBe(13550);
    expect(entry.lines[0]!.amount.currencyCode).toBe("SAR");
    expect(entry.lines[0]!.baseAmount.currencyCode).toBe("YER");
  });

  // ===== اختبار فشل الترحيل في فترة مُقفَلة =====
  it("يرفض الترحيل في فترة محاسبية مُقفَلة", async () => {
    db.prepare(`
      INSERT INTO fiscal_periods (id, tenant_id, period_key, start_date, end_date, status)
      VALUES ('fp-1', ?, '2025-01', '2025-01-01', '2025-01-31', 'closed')
    `).run(TENANT_ID);

    await expect(
      engine.postEntry({
        tenantId: TENANT_ID,
        entryDate: new Date("2025-01-15"),
        descriptionSimple: "محاولة ترحيل في فترة مقفلة",
        sourceType: "manual",
        baseCurrencyCode: "YER",
        lines: [
          { accountCode: "1101", side: "debit", amount: "1000", currencyCode: "YER", exchangeRateUsed: "1" },
          { accountCode: "4150", side: "credit", amount: "1000", currencyCode: "YER", exchangeRateUsed: "1" },
        ],
      })
    ).rejects.toThrow(FiscalPeriodClosedError);
  });

  // ===== اختبار الملخص المبسّط لغير المحاسب =====
  it("ينتج ملخصًا مبسّطًا بلا مصطلحات محاسبية (مدين/دائن)", async () => {
    const entry = await engine.postEntry({
      tenantId: TENANT_ID,
      entryDate: new Date("2025-01-15"),
      descriptionSimple: "بيع نقدي",
      sourceType: "sale",
      baseCurrencyCode: "YER",
      lines: [
        { accountCode: "1101", side: "debit", amount: "10000", currencyCode: "YER", exchangeRateUsed: "1" },
        { accountCode: "4150", side: "credit", amount: "10000", currencyCode: "YER", exchangeRateUsed: "1" },
      ],
    });

    const summary = await engine.renderSimpleSummary(entry, TENANT_ID);

    expect(summary).toContain("الصندوق الرئيسي يزيد");
    expect(summary).toContain("إيرادات المبيعات يزيد");
    expect(summary).not.toMatch(/مدين|دائن/); // تأكيد صريح على غياب المصطلحات الفنية
  });

  // ===== اختبار منع الترحيل على حساب رأس (Header) =====
  it("يرفض الترحيل على حساب تجميعي (is_header)", async () => {
    db.prepare(`
      INSERT INTO accounts (id, tenant_id, code, name_ar_simple, account_type, normal_balance, is_header, is_postable)
      VALUES ('acc-1000', ?, '1000', 'الأصول', 'asset', 'debit', 1, 0)
    `).run(TENANT_ID);

    await expect(
      engine.postEntry({
        tenantId: TENANT_ID,
        entryDate: new Date("2025-01-15"),
        descriptionSimple: "محاولة خاطئة",
        sourceType: "manual",
        baseCurrencyCode: "YER",
        lines: [
          { accountCode: "1000", side: "debit", amount: "1000", currencyCode: "YER", exchangeRateUsed: "1" },
          { accountCode: "4150", side: "credit", amount: "1000", currencyCode: "YER", exchangeRateUsed: "1" },
        ],
      })
    ).rejects.toThrow(/حساب تجميعي/);
  });
});
// ملاحظة: اختبار Fuzz لقاعدة التقريب (القسم 3.3 من تصميم القوالب) موجود في tests/golden-cases/rounding.fuzz.test.ts
