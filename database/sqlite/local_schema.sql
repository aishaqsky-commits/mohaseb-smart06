-- src/infrastructure/sqlite/schema.sql

CREATE TABLE IF NOT EXISTS accounts (
    id              TEXT PRIMARY KEY,
    tenant_id       TEXT NOT NULL,
    code            TEXT NOT NULL,
    name_ar_simple  TEXT NOT NULL,
    account_type    TEXT NOT NULL CHECK (account_type IN ('asset','liability','equity','revenue','expense')),
    normal_balance  TEXT NOT NULL CHECK (normal_balance IN ('debit','credit')),
    is_header       INTEGER NOT NULL DEFAULT 0,
    is_postable     INTEGER NOT NULL DEFAULT 1,
    is_active       INTEGER NOT NULL DEFAULT 1,
    CHECK (is_header != is_postable),
    UNIQUE(tenant_id, code)
);

CREATE INDEX IF NOT EXISTS idx_accounts_tenant_type ON accounts(tenant_id, account_type);

CREATE TABLE IF NOT EXISTS fiscal_periods (
    id              TEXT PRIMARY KEY,
    tenant_id       TEXT NOT NULL,
    period_key      TEXT NOT NULL,
    start_date      TEXT NOT NULL,
    end_date        TEXT NOT NULL,
    status          TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','closed')),
    UNIQUE(tenant_id, period_key)
);

CREATE TABLE IF NOT EXISTS journal_entries (
    id                      TEXT PRIMARY KEY,
    tenant_id               TEXT NOT NULL,
    entry_date              TEXT NOT NULL,
    description_simple      TEXT NOT NULL,
    source_type             TEXT NOT NULL,
    source_transaction_id   TEXT,
    reversal_of_entry_id    TEXT,
    is_reversed             INTEGER NOT NULL DEFAULT 0,
    base_currency_code      TEXT NOT NULL,
    created_at              TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_journal_entries_tenant_date ON journal_entries(tenant_id, entry_date);

CREATE TABLE IF NOT EXISTS journal_lines (
    id                    TEXT PRIMARY KEY,
    journal_entry_id      TEXT NOT NULL REFERENCES journal_entries(id),
    account_id            TEXT NOT NULL REFERENCES accounts(id),
    contact_id            TEXT,
    side                  TEXT NOT NULL CHECK (side IN ('debit','credit')),
    amount                TEXT NOT NULL,       -- نص لتفادي فقد الدقة (Decimal كنص)
    currency_code         TEXT NOT NULL,
    exchange_rate_used    TEXT NOT NULL,
    base_amount           TEXT NOT NULL,       -- نص أيضًا
    line_order            INTEGER NOT NULL,
    memo_ar               TEXT
);

CREATE INDEX IF NOT EXISTS idx_journal_lines_account ON journal_lines(account_id, journal_entry_id);
CREATE INDEX IF NOT EXISTS idx_journal_lines_entry ON journal_lines(journal_entry_id);
