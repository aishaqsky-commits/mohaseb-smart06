import { Account } from "../src/domain/entities/Account";

describe("Account Entity", () => {
  it("should create an account correctly using reconstruct", () => {
    const account = Account.reconstruct({
      id: "acc-1",
      tenantId: "tenant-1",
      code: "1100",
      nameArSimple: "الصندوق",
      accountType: "asset",
      normalBalance: "debit",
      isHeader: false,
      isPostable: true,
      isActive: true,
    });

    expect(account.id).toBe("acc-1");
    expect(account.tenantId).toBe("tenant-1");
    expect(account.code).toBe("1100");
    expect(account.nameArSimple).toBe("الصندوق");
    expect(account.accountType).toBe("asset");
    expect(account.normalBalance).toBe("debit");
  });

  it("should throw error if asserting postable on header account", () => {
    const account = Account.reconstruct({
      id: "acc-2",
      tenantId: "tenant-1",
      code: "1000",
      nameArSimple: "الأصول",
      accountType: "asset",
      normalBalance: "debit",
      isHeader: true,
      isPostable: false,
      isActive: true,
    });

    expect(() => account.assertIsPostable()).toThrow(/حساب تجميعي/);
  });

  it("should throw error if asserting postable on inactive account", () => {
    const account = Account.reconstruct({
      id: "acc-3",
      tenantId: "tenant-1",
      code: "1100",
      nameArSimple: "الصندوق",
      accountType: "asset",
      normalBalance: "debit",
      isHeader: false,
      isPostable: true,
      isActive: false,
    });

    expect(() => account.assertIsPostable()).toThrow(/غير نشط/);
  });

  it("should resolve direction effect correctly", () => {
    const assetAccount = Account.reconstruct({
      id: "acc-1",
      tenantId: "tenant-1",
      code: "1100",
      nameArSimple: "الصندوق",
      accountType: "asset",
      normalBalance: "debit",
      isHeader: false,
      isPostable: true,
      isActive: true,
    });

    expect(assetAccount.resolveDirectionEffect("debit")).toBe("increase");
    expect(assetAccount.resolveDirectionEffect("credit")).toBe("decrease");

    const liabilityAccount = Account.reconstruct({
      id: "acc-4",
      tenantId: "tenant-1",
      code: "2100",
      nameArSimple: "الموردون",
      accountType: "liability",
      normalBalance: "credit",
      isHeader: false,
      isPostable: true,
      isActive: true,
    });

    expect(liabilityAccount.resolveDirectionEffect("credit")).toBe("increase");
    expect(liabilityAccount.resolveDirectionEffect("debit")).toBe("decrease");
  });
});
