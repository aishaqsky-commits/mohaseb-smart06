// src/application/JournalEngine.ts

import { Account } from "../domain/entities/Account";
import { JournalEntry, JournalEntrySourceType } from "../domain/entities/JournalEntry";
import { JournalLine, EntrySide } from "../domain/entities/JournalLine";
import { Money } from "../domain/value-objects/Money";
import { AccountRepository } from "../domain/ports/AccountRepository";
import { JournalRepository } from "../domain/ports/JournalRepository";
import {
  AccountNotFoundError,
  EntryNotFoundError,
  FiscalPeriodClosedError,
  EntryAlreadyReversedError,
} from "../domain/errors/AccountingErrors";

export interface PostLineRequest {
  accountCode: string;       // نستخدم الكود لا الـ ID (كما أوصينا في تصميم القوالب)
  side: EntrySide;
  amount: string;             // نص لتفادي أخطاء float من الطبقات الخارجية (API/UI)
  currencyCode: string;
  exchangeRateUsed: string;
  contactId?: string | undefined;
  memoAr?: string | undefined;
}

export interface PostJournalEntryRequest {
  tenantId: string;
  entryDate: Date;
  descriptionSimple: string;
  sourceType: JournalEntrySourceType;
  sourceTransactionId?: string | undefined;
  baseCurrencyCode: string;
  lines: PostLineRequest[];
}

/**
 * الواجهة الوحيدة المعتمدة لترحيل أي قيد في كامل النظام.
 * كل القوالب (بيع/شراء/تالف...) يجب أن تمر عبر هذه الدالة فقط، لا بناء JournalEntry يدويًا في مكان آخر.
 */
export class JournalEngine {
  constructor(
    private readonly accountRepo: AccountRepository,
    private readonly journalRepo: JournalRepository
  ) {}

  async postEntry(request: PostJournalEntryRequest): Promise<JournalEntry> {
    // 1) خط الدفاع الأول: الفترة المحاسبية مفتوحة؟
    const periodStatus = await this.journalRepo.getFiscalPeriodStatus(
      request.tenantId,
      request.entryDate
    );
    if (periodStatus.isClosed) {
      throw new FiscalPeriodClosedError(request.entryDate.toISOString());
    }

    // 2) جلب كل الحسابات المطلوبة دفعة واحدة (أداء - تفادي N+1 Query)
    const accountCodes = request.lines.map((l) => l.accountCode);
    const accountsMap = await this.accountRepo.findManyByCodes(
      request.tenantId,
      accountCodes
    );

    // 3) بناء كل سطر مع التحقق من صلاحية الحساب للترحيل
    const lines: JournalLine[] = request.lines.map((lineReq, index) => {
      const account = accountsMap.get(lineReq.accountCode);
      if (!account) {
        throw new AccountNotFoundError(lineReq.accountCode);
      }
      account.assertIsPostable();

      const money = Money.fromDecimalString(lineReq.amount, lineReq.currencyCode);

      return JournalLine.create({
        accountId: account.id,
        side: lineReq.side,
        amount: money,
        exchangeRateUsed: lineReq.exchangeRateUsed,
        baseCurrencyCode: request.baseCurrencyCode,
        contactId: lineReq.contactId ?? null,
        memoAr: lineReq.memoAr ?? null,
        lineOrder: index,
      });
    });

    // 4) إنشاء القيد (يفرض التوازن تلقائيًا داخل JournalEntry.create - خط الدفاع الثاني)
    const entry = JournalEntry.create({
      tenantId: request.tenantId,
      entryDate: request.entryDate,
      descriptionSimple: request.descriptionSimple,
      sourceType: request.sourceType,
      sourceTransactionId: request.sourceTransactionId,
      baseCurrencyCode: request.baseCurrencyCode,
      lines,
    });

    // 5) الحفظ الذري (رأس + أسطر في معاملة واحدة، يُنفَّذ داخل Infrastructure)
    await this.journalRepo.save(entry);

    return entry;
  }

  async reverseEntry(
    tenantId: string,
    entryId: string,
    reason: string
  ): Promise<JournalEntry> {
    const original = await this.journalRepo.findById(tenantId, entryId);
    if (!original) {
      throw new EntryNotFoundError(entryId);
    }
    if (original.isReversed) {
      throw new EntryAlreadyReversedError(entryId);
    }

    const periodStatus = await this.journalRepo.getFiscalPeriodStatus(
      tenantId,
      new Date()
    );
    if (periodStatus.isClosed) {
      throw new FiscalPeriodClosedError(new Date().toISOString());
    }

    const reversalEntry = original.createReversal(reason);
    await this.journalRepo.save(reversalEntry);
    await this.journalRepo.save(original.markAsReversed());

    return reversalEntry;
  }

  /**
   * توليد الملخص المبسّط لغير المحاسب - يحقق فلسفة "لا مصطلحات محاسبية"
   * المصممة في وحدة القوالب سابقًا.
   */
  async renderSimpleSummary(
    entry: JournalEntry,
    tenantId: string
  ): Promise<string> {
    const sentences: string[] = [];

    for (const line of entry.lines) {
      const account = await this.accountRepo.findById(tenantId, line.accountId);
      if (!account) continue;

      const effect = account.resolveDirectionEffect(line.side);
      const verb = effect === "increase" ? "يزيد" : "ينقص";
      sentences.push(`${account.nameArSimple} ${verb} ${line.amount.toDisplayString()}`);
    }

    return sentences.join(" · ");
  }
}
