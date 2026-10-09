// src/application/FinancialReportingEngine.ts

import { ReportingRepository, BalanceSnapshot } from "../domain/ports/ReportingRepository";

export interface TrialBalanceRow {
  accountCode: string;
  accountName: string;
  openingBalance: number;
  periodDebit: number;
  periodCredit: number;
  closingBalance: number;
}

export interface IncomeStatementRow {
  accountCode: string;
  accountName: string;
  netAmount: number;
}

export interface BalanceSheetRow {
  accountCode: string;
  accountName: string;
  balance: number;
}

export class FinancialReportingEngine {
  constructor(private readonly reportingRepo: ReportingRepository) {}

  /**
   * توليد تقرير ميزان المراجعة (Trial Balance) حتى تاريخ محدد
   */
  async generateTrialBalance(tenantId: string, asOfDate: Date): Promise<TrialBalanceRow[]> {
    const snapshots = await this.reportingRepo.getAccountBalancesAsOf(tenantId, asOfDate);
    
    return snapshots.map(snap => ({
      accountCode: snap.accountCode,
      accountName: snap.accountName,
      openingBalance: snap.openingBalance,
      periodDebit: snap.periodDebit,
      periodCredit: snap.periodCredit,
      closingBalance: snap.closingBalance,
    }));
  }

  /**
   * توليد قائمة الدخل (Income Statement) لفترة محددة
   * يجلب الحسابات التي تبدأ بـ 4 (إيرادات) و 5 (مصروفات)
   */
  async generateIncomeStatement(tenantId: string, dateFrom: Date, dateTo: Date) {
    const activity = await this.reportingRepo.getAccountActivityForRange(tenantId, dateFrom, dateTo);
    
    let totalRevenue = 0;
    let totalExpenses = 0;
    
    const rows: IncomeStatementRow[] = [];

    for (const acc of activity) {
      if (acc.accountCode.startsWith('4')) {
        // الإيرادات طبيعتها دائنة
        const net = acc.periodCredit - acc.periodDebit;
        totalRevenue += net;
        rows.push({ accountCode: acc.accountCode, accountName: acc.accountName, netAmount: net });
      } else if (acc.accountCode.startsWith('5')) {
        // المصروفات طبيعتها مدينة
        const net = acc.periodDebit - acc.periodCredit;
        totalExpenses += net;
        rows.push({ accountCode: acc.accountCode, accountName: acc.accountName, netAmount: net });
      }
    }

    const netProfit = totalRevenue - totalExpenses;

    return {
      rows,
      totalRevenue,
      totalExpenses,
      netProfit,
    };
  }

  /**
   * توليد الميزانية العمومية (Balance Sheet) حتى تاريخ محدد
   * يجلب الحسابات التي تبدأ بـ 1 (أصول)، 2 (خصوم)، 3 (حقوق ملكية)
   */
  async generateBalanceSheet(tenantId: string, asOfDate: Date) {
    const snapshots = await this.reportingRepo.getAccountBalancesAsOf(tenantId, asOfDate);
    
    let totalAssets = 0;
    let totalLiabilities = 0;
    let totalEquity = 0;
    
    const assets: BalanceSheetRow[] = [];
    const liabilities: BalanceSheetRow[] = [];
    const equity: BalanceSheetRow[] = [];

    for (const snap of snapshots) {
      const balance = snap.closingBalance;
      if (snap.accountCode.startsWith('1')) {
        totalAssets += balance;
        assets.push({ accountCode: snap.accountCode, accountName: snap.accountName, balance });
      } else if (snap.accountCode.startsWith('2')) {
        // الالتزامات بطبيعتها دائنة (تكون سالبة في الميزان عادةً إذا كنا نستخدم الإشارات الرياضية، لكننا نعكسها للعرض)
        const displayBalance = -balance; 
        totalLiabilities += displayBalance;
        liabilities.push({ accountCode: snap.accountCode, accountName: snap.accountName, balance: displayBalance });
      } else if (snap.accountCode.startsWith('3')) {
        const displayBalance = -balance;
        totalEquity += displayBalance;
        equity.push({ accountCode: snap.accountCode, accountName: snap.accountName, balance: displayBalance });
      }
    }

    return {
      assets,
      liabilities,
      equity,
      totalAssets,
      totalLiabilitiesAndEquity: totalLiabilities + totalEquity,
    };
  }
}
