import { ARAPSubledgerEngine } from "../../src/application/ARAPSubledgerEngine";
import { ReportingRepository, BalanceSnapshot, ARAPContactBalance } from "../../src/domain/ports/ReportingRepository";

class MockReportingRepository implements ReportingRepository {
  async getAccountBalancesAsOf(tenantId: string, asOfDate: Date): Promise<BalanceSnapshot[]> {
    return [];
  }

  async getAccountActivityForRange(tenantId: string, dateFrom: Date, dateTo: Date): Promise<BalanceSnapshot[]> {
    return [];
  }

  async getARAPContactBalances(tenantId: string): Promise<ARAPContactBalance[]> {
    return [
      { contactId: 'c1', contactName: 'أحمد', currencyCode: 'YER', totalOutstandingBase: 5000, openItemsCount: 2, oldestDueDate: new Date('2025-01-01') },
      { contactId: 'c2', contactName: 'شركة النور', currencyCode: 'YER', totalOutstandingBase: 12000, openItemsCount: 1, oldestDueDate: new Date('2024-11-01') },
    ];
  }
}

describe('ARAPSubledgerEngine', () => {
  let engine: ARAPSubledgerEngine;
  let repo: MockReportingRepository;

  beforeEach(() => {
    repo = new MockReportingRepository();
    engine = new ARAPSubledgerEngine(repo);
  });

  test('getContactBalancesSummary returns standard balances', async () => {
    const balances = await engine.getContactBalancesSummary('tenant-1');
    expect(balances.length).toBe(2);
    expect(balances[0].contactName).toBe('أحمد');
  });

  test('generateAgingReport buckets outstanding balances by days correctly', async () => {
    // We will test relative to a specific date to ensure deterministic bucket tests
    const asOfDate = new Date('2025-01-15'); // c1 is 14 days old (current), c2 is ~75 days old (over60)
    
    const aging = await engine.generateAgingReport('tenant-1', asOfDate);
    
    expect(aging.length).toBe(2);
    
    // c1 (أحمد) -> 14 days difference -> bucket: current
    expect(aging[0].current).toBe(5000);
    expect(aging[0].over30).toBe(0);
    
    // c2 (شركة النور) -> ~75 days difference -> bucket: over60
    expect(aging[1].current).toBe(0);
    expect(aging[1].over30).toBe(0);
    expect(aging[1].over60).toBe(12000);
  });
});
