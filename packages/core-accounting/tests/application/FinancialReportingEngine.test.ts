import { FinancialReportingEngine } from "../../src/application/FinancialReportingEngine";
import { ReportingRepository, BalanceSnapshot } from "../../src/domain/ports/ReportingRepository";

class MockReportingRepository implements ReportingRepository {
  async getAccountBalancesAsOf(tenantId: string, asOfDate: Date): Promise<BalanceSnapshot[]> {
    return [
      { accountId: '1', accountCode: '1101', accountName: 'الصندوق', openingBalance: 0, periodDebit: 1000, periodCredit: 200, closingBalance: 800 },
      { accountId: '2', accountCode: '2101', accountName: 'موردين', openingBalance: 0, periodDebit: 0, periodCredit: 500, closingBalance: -500 },
      { accountId: '3', accountCode: '3101', accountName: 'رأس المال', openingBalance: 0, periodDebit: 0, periodCredit: 1000, closingBalance: -1000 },
      { accountId: '4', accountCode: '4101', accountName: 'مبيعات', openingBalance: 0, periodDebit: 0, periodCredit: 1500, closingBalance: -1500 },
      { accountId: '5', accountCode: '5101', accountName: 'مصروفات إيجار', openingBalance: 0, periodDebit: 300, periodCredit: 0, closingBalance: 300 },
    ];
  }

  async getAccountActivityForRange(tenantId: string, dateFrom: Date, dateTo: Date): Promise<BalanceSnapshot[]> {
    return [
      { accountId: '4', accountCode: '4101', accountName: 'مبيعات', openingBalance: 0, periodDebit: 100, periodCredit: 1500, closingBalance: -1400 },
      { accountId: '5', accountCode: '5101', accountName: 'مصروفات إيجار', openingBalance: 0, periodDebit: 300, periodCredit: 50, closingBalance: 250 },
    ];
  }

  async getARAPContactBalances(tenantId: string) {
    return [];
  }
}

describe('FinancialReportingEngine', () => {
  let engine: FinancialReportingEngine;
  let repo: MockReportingRepository;

  beforeEach(() => {
    repo = new MockReportingRepository();
    engine = new FinancialReportingEngine(repo);
  });

  test('generateTrialBalance should return all accounts', async () => {
    const tb = await engine.generateTrialBalance('tenant-1', new Date());
    expect(tb.length).toBe(5);
    expect(tb[0].accountCode).toBe('1101');
    expect(tb[0].closingBalance).toBe(800);
  });

  test('generateIncomeStatement should calculate revenues, expenses, and net profit', async () => {
    const income = await engine.generateIncomeStatement('tenant-1', new Date('2025-01-01'), new Date('2025-01-31'));
    
    // Revenue (Credit - Debit) => 1500 - 100 = 1400
    expect(income.totalRevenue).toBe(1400);
    // Expenses (Debit - Credit) => 300 - 50 = 250
    expect(income.totalExpenses).toBe(250);
    // Net Profit => 1400 - 250 = 1150
    expect(income.netProfit).toBe(1150);

    expect(income.rows.length).toBe(2);
    expect(income.rows[0].accountCode).toBe('4101');
    expect(income.rows[0].netAmount).toBe(1400);
  });

  test('generateBalanceSheet should group assets, liabilities, and equity properly', async () => {
    const bs = await engine.generateBalanceSheet('tenant-1', new Date());
    
    expect(bs.assets.length).toBe(1);
    expect(bs.totalAssets).toBe(800); // 1101: 800

    expect(bs.liabilities.length).toBe(1);
    expect(bs.totalLiabilitiesAndEquity).toBe(1500); // Liabilities 500 + Equity 1000
    
    // Liabilities is -(-500) = 500
    expect(bs.liabilities[0].balance).toBe(500);
  });
});
