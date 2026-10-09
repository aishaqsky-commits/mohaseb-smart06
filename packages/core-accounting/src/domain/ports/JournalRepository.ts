// src/domain/ports/JournalRepository.ts

import { JournalEntry } from "../entities/JournalEntry";

export interface FiscalPeriodStatus {
  isClosed: boolean;
}

export interface JournalRepository {
  /** يجب أن تُنفَّذ كمعاملة ذرية واحدة (رأس القيد + كل الأسطر معًا) */
  save(entry: JournalEntry): Promise<void>;
  findById(tenantId: string, entryId: string): Promise<JournalEntry | null>;
  getFiscalPeriodStatus(tenantId: string, entryDate: Date): Promise<FiscalPeriodStatus>;
}

// فائدة هذا الفصل: JournalEngine أدناه لا يعرف شيئًا عن SQLite أو PostgreSQL —
// يمكن اختباره بالكامل بمستودعات وهمية (In-Memory Fakes)، ويمكن استبدال التخزين
// لاحقًا دون تعديل منطق الأعمال.
