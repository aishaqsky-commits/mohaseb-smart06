// src/application/ARAPSubledgerEngine.ts

import { ReportingRepository, ARAPContactBalance } from "../domain/ports/ReportingRepository";

export interface ARAPAgingSummary {
  contactId: string;
  contactName: string;
  currencyCode: string;
  totalOutstanding: number;
  current: number; // 0-30 days
  over30: number; // 31-60 days
  over60: number; // 61-90 days
  over90: number; // >90 days
}

export class ARAPSubledgerEngine {
  constructor(private readonly reportingRepo: ReportingRepository) {}

  /**
   * تقرير ملخص أرصدة العملاء والموردين (Contact Balances)
   */
  async getContactBalancesSummary(tenantId: string): Promise<ARAPContactBalance[]> {
    return await this.reportingRepo.getARAPContactBalances(tenantId);
  }

  /**
   * تقرير أعمار الديون (Aging Report)
   * يعتمد على أقدم تاريخ استحقاق لكل عميل كطريقة تقريبية لعدم وجود تفاصيل الفواتير حالياً،
   * أو يفترض استخدام logic محدد سيتم ربطه بقاعدة البيانات لاحقاً.
   */
  async generateAgingReport(tenantId: string, asOfDate: Date): Promise<ARAPAgingSummary[]> {
    const balances = await this.reportingRepo.getARAPContactBalances(tenantId);
    
    return balances.map(b => {
      let current = 0;
      let over30 = 0;
      let over60 = 0;
      let over90 = 0;

      if (b.oldestDueDate) {
        const diffTime = Math.abs(asOfDate.getTime() - b.oldestDueDate.getTime());
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

        if (diffDays <= 30) current = b.totalOutstandingBase;
        else if (diffDays <= 60) over30 = b.totalOutstandingBase;
        else if (diffDays <= 90) over60 = b.totalOutstandingBase;
        else over90 = b.totalOutstandingBase;
      } else {
        // If no due date, assume current
        current = b.totalOutstandingBase;
      }

      return {
        contactId: b.contactId,
        contactName: b.contactName,
        currencyCode: b.currencyCode,
        totalOutstanding: b.totalOutstandingBase,
        current,
        over30,
        over60,
        over90,
      };
    });
  }
}
