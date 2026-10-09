// src/index.ts

export { Money, InvalidMoneyOperationError } from "./domain/value-objects/Money";
export { Account, AccountType, NormalBalance, AccountProps } from "./domain/entities/Account";
export { JournalEntry, JournalEntrySourceType, CreateJournalEntryInput } from "./domain/entities/JournalEntry";
export { JournalLine, EntrySide, CreateJournalLineInput } from "./domain/entities/JournalLine";
export * from "./domain/errors/AccountingErrors";
export { JournalEngine, PostJournalEntryRequest, PostLineRequest } from "./application/JournalEngine";
export type { AccountRepository } from "./domain/ports/AccountRepository";
export type { JournalRepository, FiscalPeriodStatus } from "./domain/ports/JournalRepository";
export { SqliteAccountRepository } from "./infrastructure/sqlite/SqliteAccountRepository";
export { SqliteJournalRepository } from "./infrastructure/sqlite/SqliteJournalRepository";

// Templates Engine & Execution
export { TemplateExecutionEngine, ExecuteTemplateRequest, ExecuteTemplateResult } from "./templates/TemplateExecutionEngine";
export { ExpressionEngine, ExpressionContext } from "./templates/engine/ExpressionEngine";
export { FunctionRegistry } from "./templates/engine/FunctionRegistry";
export { Lexer } from "./templates/engine/Lexer";
export { Parser } from "./templates/engine/Parser";
export * from "./templates/engine/errors";
export { TemplateRegistry, TemplateNotFoundError } from "./templates/registry/TemplateRegistry";
export { TemplateValidator, TemplateValidationError } from "./templates/validation/TemplateValidator";

// Template Ports & Types
export type { ExchangeRateProviderPort } from "./templates/ports/ExchangeRateProviderPort";
export type { InventoryCostingPort } from "./templates/ports/InventoryCostingPort";
export type { PostActionContext, PostActionHandler } from "./templates/ports/PostActionPort";
export { PostActionRegistry } from "./templates/ports/PostActionPort";
export * from "./templates/types/TemplateDefinition";

