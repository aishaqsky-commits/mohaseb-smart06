// src/domain/errors/AccountingErrors.ts

export class UnbalancedJournalEntryError extends Error {
  constructor(totalDebit: string, totalCredit: string) {
    super(
      `القيد غير متوازن: إجمالي المدين (${totalDebit}) لا يساوي إجمالي الدائن (${totalCredit})`
    );
    this.name = "UnbalancedJournalEntryError";
  }
}

export class FiscalPeriodClosedError extends Error {
  constructor(entryDate: string) {
    super(`الفترة المحاسبية لتاريخ ${entryDate} مُقفَلة، لا يمكن الترحيل فيها`);
    this.name = "FiscalPeriodClosedError";
  }
}

export class AccountNotFoundError extends Error {
  constructor(accountId: string) {
    super(`الحساب غير موجود: ${accountId}`);
    this.name = "AccountNotFoundError";
  }
}

export class EntryAlreadyReversedError extends Error {
  constructor(entryId: string) {
    super(`القيد ${entryId} معكوس مسبقًا، لا يمكن عكسه مرة أخرى`);
    this.name = "EntryAlreadyReversedError";
  }
}
