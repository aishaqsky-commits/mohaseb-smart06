import { PostActionRegistry, PostActionContext } from "../../src/templates/ports/PostActionPort";

describe("PostActionRegistry", () => {
  let registry: PostActionRegistry;
  let mockContext: PostActionContext;

  beforeEach(() => {
    registry = new PostActionRegistry();
    mockContext = {
      tenantId: "tenant-1",
      transactionId: "tx-1",
      payload: { amount: 100 },
    };
  });

  it("should register and execute a handler successfully", async () => {
    const handler = jest.fn().mockResolvedValue(undefined);
    registry.register("allocatePayment", handler);

    await registry.execute("allocatePayment(inv_1, 100)", mockContext);

    expect(handler).toHaveBeenCalledTimes(1);
    expect(handler).toHaveBeenCalledWith(["inv_1", "100"], mockContext);
  });

  it("should throw an error for invalid action expression format", async () => {
    await expect(registry.execute("invalidFormat", mockContext)).rejects.toThrow(
      /صيغة post_action غير صالحة/
    );
  });

  it("should log a warning and ignore if no handler is registered", async () => {
    const consoleSpy = jest.spyOn(console, "warn").mockImplementation(() => {});
    
    await registry.execute("unknownAction(arg1)", mockContext);
    
    expect(consoleSpy).toHaveBeenCalledWith(
      expect.stringContaining('لا معالج مسجَّل للإجراء "unknownAction"')
    );
    
    consoleSpy.mockRestore();
  });

  it("should parse arguments correctly, removing curly braces", async () => {
    const handler = jest.fn().mockResolvedValue(undefined);
    registry.register("apply_fx", handler);

    await registry.execute("apply_fx({inv_id}, {amount})", mockContext);

    expect(handler).toHaveBeenCalledWith(["inv_id", "amount"], mockContext);
  });
});
