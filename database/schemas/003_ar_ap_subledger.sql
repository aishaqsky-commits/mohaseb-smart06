-- =========================================================================
-- Migration 003: AR/AP Sub-Ledger & Aging Engine Schema
-- Platform: Smart Merchant Accounting (Open Item Accounting)
-- =========================================================================

CREATE TABLE IF NOT EXISTS ar_ap_open_items (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    contact_id UUID NOT NULL,
    subledger_type VARCHAR(2) NOT NULL CHECK (subledger_type IN ('AR', 'AP')),
    journal_entry_id UUID NOT NULL,
    invoice_number VARCHAR(50),
    invoice_date DATE NOT NULL,
    due_date DATE,
    original_amount DECIMAL(18, 4) NOT NULL CHECK (original_amount > 0),
    remaining_amount DECIMAL(18, 4) NOT NULL CHECK (remaining_amount >= 0),
    currency_code VARCHAR(3) NOT NULL,
    exchange_rate DECIMAL(18, 6) DEFAULT 1.0,
    base_remaining_amount DECIMAL(18, 4) NOT NULL,
    status VARCHAR(20) DEFAULT 'open' CHECK (status IN ('open', 'partially_paid', 'settled', 'disputed')),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    origin_device_id UUID,
    lamport_clock BIGINT DEFAULT 0,
    is_deleted BOOLEAN DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_open_items_contact ON ar_ap_open_items(tenant_id, contact_id, status);
CREATE INDEX IF NOT EXISTS idx_open_items_aging ON ar_ap_open_items(tenant_id, subledger_type, due_date, remaining_amount);

CREATE TABLE IF NOT EXISTS ar_ap_allocations (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    open_item_id UUID NOT NULL REFERENCES ar_ap_open_items(id),
    payment_journal_entry_id UUID NOT NULL,
    allocated_amount DECIMAL(18, 4) NOT NULL CHECK (allocated_amount > 0),
    currency_code VARCHAR(3) NOT NULL,
    exchange_rate DECIMAL(18, 6) DEFAULT 1.0,
    base_allocated_amount DECIMAL(18, 4) NOT NULL,
    allocation_date DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_allocations_open_item ON ar_ap_allocations(open_item_id);

CREATE TABLE IF NOT EXISTS contact_credit_holds (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    contact_id UUID NOT NULL,
    reason TEXT NOT NULL,
    hold_placed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    hold_released_at TIMESTAMPTZ,
    placed_by_user_id UUID,
    released_by_user_id UUID
);

CREATE TABLE IF NOT EXISTS ar_ap_reminders (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    contact_id UUID NOT NULL,
    open_item_id UUID REFERENCES ar_ap_open_items(id),
    reminder_channel VARCHAR(20) DEFAULT 'whatsapp',
    sent_content TEXT NOT NULL,
    sent_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS contact_balances (
    tenant_id UUID NOT NULL,
    contact_id UUID NOT NULL,
    total_debit DECIMAL(18, 4) DEFAULT 0,
    total_credit DECIMAL(18, 4) DEFAULT 0,
    net_balance DECIMAL(18, 4) DEFAULT 0,
    open_ar_balance DECIMAL(18, 4) DEFAULT 0,
    open_ap_balance DECIMAL(18, 4) DEFAULT 0,
    last_payment_date DATE,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (tenant_id, contact_id)
);
