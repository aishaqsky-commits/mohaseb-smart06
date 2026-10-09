// src/domain/entities/JournalLine.ts

import { v4 as uuidv4 } from "uuid";
import { Money } from "../value-objects/Money";

export type EntrySide = "debit" | "credit";

export interface CreateJournalLineInput {
  accountId: string;
  side: EntrySide;
  amount: Money;            // بعملة السطر نفسها
  exchangeRateUsed: string; // سعر الصرف وقت الإنشاء (مثبّت)
  baseCurrencyCode: string; // عملة الـ Tenant الأساسية
  contactId?: string | null;
  memoAr?: string | null;
  lineOrder: number;
}

export class JournalLine {
  readonly id!: string;
  readonly accountId!: string;
  readonly side!: EntrySide;
  readonly amount!: Money;              // بعملة السطر
  readonly baseAmount!: Money;          // محسوبة بعملة الأساس (مثبّتة وقت الإنشاء)
  readonly exchangeRateUsed!: string;
  readonly contactId!: string | null;
  readonly memoAr!: string | null;
  readonly lineOrder!: number;

  private constructor(props: {
    id: string;
    accountId: string;
    side: EntrySide;
    amount: Money;
    baseAmount: Money;
    exchangeRateUsed: string;
    contactId: string | null;
    memoAr: string | null;
    lineOrder: number;
  }) {
    if (props.amount.isZero() || props.amount.isNegative()) {
      throw new Error("مبلغ سطر القيد يجب أن يكون أكبر من صفر");
    }
    // تعيين الخصائص عبر مفاتيح معروفة لضمان توافق strictPropertyInitialization
    for (const [k, v] of Object.entries(props)) {
      (this as Record<string, unknown>)[k] = v;
    }
  }

  static create(input: CreateJournalLineInput): JournalLine {
    const baseAmount = input.amount.convertTo(
      input.baseCurrencyCode,
      input.exchangeRateUsed
    );

    return new JournalLine({
      id: uuidv4(),
      accountId: input.accountId,
      side: input.side,
      amount: input.amount,
      baseAmount,
      exchangeRateUsed: input.exchangeRateUsed,
      contactId: input.contactId ?? null,
      memoAr: input.memoAr ?? null,
      lineOrder: input.lineOrder,
    });
  }

  /** إعادة بناء من صف قاعدة بيانات (لا يُعيد حساب baseAmount، يثق بالمخزَّن) */
  static reconstruct(props: {
    id: string;
    accountId: string;
    side: EntrySide;
    amount: Money;
    baseAmount: Money;
    exchangeRateUsed: string;
    contactId: string | null;
    memoAr: string | null;
    lineOrder: number;
  }): JournalLine {
    return new JournalLine(props);
  }
}
