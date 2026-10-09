// src/domain/ports/ReportingRepository.ts

export interface BalanceSnapshot {
  accountId: string;
  accountCode: string;
  accountName: string;
  openingBalance: number;
  periodDebit: number;
  periodCredit: number;
  closingBalance: number;
}

export interface ARAPContactBalance {
  contactId: string;
  contactName: string;
  currencyCode: string;
  totalOutstandingBase: number;
  openItemsCount: number;
  oldestDueDate: Date | null;
}

export interface ReportingRepository {
  /**
   * جلب الأرصدة المجمعة المفتوحة (الرصيد الحي + الحركات الأخيرة) لحساب معين
   */
  getAccountBalancesAsOf(tenantId: string, asOfDate: Date): Promise<BalanceSnapshot[]>;
  
  /**
   * جلب حركات الحساب خلال فترة معينة من الفترات الساخنة والباردة (للأرباح والخسائر)
   */
  getAccountActivityForRange(tenantId: string, dateFrom: Date, dateTo: Date): Promise<BalanceSnapshot[]>;

  /**
   * جلب أرصدة جهات الاتصال التفصيلية للذمم المدينة والدائنة
   */
  getARAPContactBalances(tenantId: string): Promise<ARAPContactBalance[]>;
}
