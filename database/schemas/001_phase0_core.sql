-- =========================================================================
-- Migration 001: Phase 0 Core Schema
-- Platform: Multi-Tenant Intelligent Accounting (Local-first / PostgreSQL)
-- Specification: Phase 0 Architecture & ERD Specifications
-- =========================================================================

-- Currencies (Static Reference)
CREATE TABLE IF NOT EXISTS currencies (
    code VARCHAR(3) PRIMARY KEY,
    name_ar VARCHAR(50) NOT NULL,
    symbol_ar VARCHAR(10) NOT NULL,
    fraction_digits SMALLINT DEFAULT 2,
    is_active BOOLEAN DEFAULT TRUE
);

INSERT INTO currencies (code, name_ar, symbol_ar, fraction_digits) VALUES
('YER', 'ريال يمني', 'ر.ي', 2),
('SAR', 'ريال سعودي', 'ر.س', 2),
('USD', 'دولار أمريكي', '$', 2)
ON CONFLICT (code) DO NOTHING;

-- Business Types (Static Reference)
CREATE TABLE IF NOT EXISTS business_types (
    code VARCHAR(30) PRIMARY KEY,
    name_ar VARCHAR(100) NOT NULL,
    default_seed_scope VARCHAR(30) NOT NULL
);

INSERT INTO business_types (code, name_ar, default_seed_scope) VALUES
('retail', 'تجزئة وتموينات', 'retail'),
('clinic', 'عيادة ومستلزمات طبية', 'clinic'),
('workshop', 'ورشة وصيانة فنية', 'workshop'),
('law_office', 'مكتب محاماة واستشارات', 'law_office'),
('service_office', 'مكتب خدمات عامة وطباعة', 'service_office')
ON CONFLICT (code) DO NOTHING;

-- Account Types (Static Reference)
CREATE TABLE IF NOT EXISTS account_types (
    code VARCHAR(20) PRIMARY KEY,
    name_ar VARCHAR(50) NOT NULL,
    normal_balance VARCHAR(6) CHECK (normal_balance IN ('debit', 'credit')),
    classification VARCHAR(20) CHECK (classification IN ('balance_sheet', 'income_statement'))
);

INSERT INTO account_types (code, name_ar, normal_balance, classification) VALUES
('asset', 'أصول', 'debit', 'balance_sheet'),
('liability', 'خصوم', 'credit', 'balance_sheet'),
('equity', 'حقوق ملكية', 'credit', 'balance_sheet'),
('revenue', 'إيرادات', 'credit', 'income_statement'),
('expense', 'مصروفات', 'debit', 'income_statement')
ON CONFLICT (code) DO NOTHING;

-- Users (Cross-tenant platform users)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(150) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    pin_hash VARCHAR(255),
    is_platform_admin BOOLEAN DEFAULT FALSE,
    two_fa_enabled BOOLEAN DEFAULT FALSE,
    two_fa_secret VARCHAR(255),
    locale VARCHAR(10) DEFAULT 'ar-YE',
    last_login_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    is_deleted BOOLEAN DEFAULT FALSE
);

-- Tenants (Merchants / Businesses)
CREATE TABLE IF NOT EXISTS tenants (
    id UUID PRIMARY KEY,
    business_name VARCHAR(150) NOT NULL,
    business_type_code VARCHAR(30) REFERENCES business_types(code),
    base_currency_code VARCHAR(3) DEFAULT 'YER' REFERENCES currencies(code),
    country_code VARCHAR(2) DEFAULT 'YE',
    timezone VARCHAR(50) DEFAULT 'Asia/Aden',
    fiscal_year_start_month SMALLINT DEFAULT 1,
    owner_user_id UUID REFERENCES users(id),
    phone VARCHAR(20),
    address TEXT,
    logo_url TEXT,
    onboarding_status VARCHAR(20) DEFAULT 'pending',
    settings JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    origin_device_id UUID,
    lamport_clock BIGINT DEFAULT 0,
    is_deleted BOOLEAN DEFAULT FALSE
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_tenants_phone ON tenants(phone);
CREATE INDEX IF NOT EXISTS idx_tenants_business_type ON tenants(business_type_code);

-- Tenant Users & Roles
CREATE TABLE IF NOT EXISTS roles (
    id UUID PRIMARY KEY,
    tenant_id UUID REFERENCES tenants(id),
    name_ar VARCHAR(50) NOT NULL,
    code VARCHAR(30) NOT NULL,
    is_system_role BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS permissions (
    id UUID PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name_ar VARCHAR(100) NOT NULL,
    module VARCHAR(30) NOT NULL
);

CREATE TABLE IF NOT EXISTS role_permissions (
    role_id UUID REFERENCES roles(id),
    permission_id UUID REFERENCES permissions(id),
    PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE IF NOT EXISTS tenant_users (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    user_id UUID NOT NULL REFERENCES users(id),
    role_id UUID REFERENCES roles(id),
    is_active BOOLEAN DEFAULT TRUE,
    joined_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tenant_id, user_id)
);

-- Devices Registry
CREATE TABLE IF NOT EXISTS devices (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    device_fingerprint VARCHAR(255) NOT NULL,
    device_name VARCHAR(100),
    platform VARCHAR(20) DEFAULT 'android',
    app_version VARCHAR(20),
    is_primary_device BOOLEAN DEFAULT FALSE,
    is_blocked BOOLEAN DEFAULT FALSE,
    last_sync_at TIMESTAMPTZ,
    registered_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tenant_id, device_fingerprint)
);

-- Multi-Currency Rates per Tenant
CREATE TABLE IF NOT EXISTS tenant_currencies (
    tenant_id UUID REFERENCES tenants(id),
    currency_code VARCHAR(3) REFERENCES currencies(code),
    is_active BOOLEAN DEFAULT TRUE,
    PRIMARY KEY (tenant_id, currency_code)
);

CREATE TABLE IF NOT EXISTS exchange_rates (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    from_currency_code VARCHAR(3) REFERENCES currencies(code),
    to_currency_code VARCHAR(3) REFERENCES currencies(code),
    rate DECIMAL(18, 6) NOT NULL,
    rate_source VARCHAR(30) DEFAULT 'manual',
    effective_date DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Chart of Accounts
CREATE TABLE IF NOT EXISTS accounts (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    code VARCHAR(30) NOT NULL,
    parent_code VARCHAR(30),
    account_type VARCHAR(20) NOT NULL REFERENCES account_types(code),
    name_ar_simple VARCHAR(150) NOT NULL,
    name_technical VARCHAR(150),
    description_ar TEXT,
    is_header BOOLEAN DEFAULT FALSE,
    is_postable BOOLEAN DEFAULT TRUE,
    is_contra BOOLEAN DEFAULT FALSE,
    is_control_account BOOLEAN DEFAULT FALSE,
    linked_contact_type VARCHAR(20),
    is_system_account BOOLEAN DEFAULT FALSE,
    is_user_modified BOOLEAN DEFAULT FALSE,
    allow_multi_currency BOOLEAN DEFAULT FALSE,
    seed_version SMALLINT DEFAULT 1,
    sort_order INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    origin_device_id UUID,
    lamport_clock BIGINT DEFAULT 0,
    is_deleted BOOLEAN DEFAULT FALSE,
    CONSTRAINT chk_accounts_header_postable CHECK (is_header = TRUE OR is_postable = TRUE),
    CONSTRAINT chk_accounts_mutual_role CHECK (NOT (is_header = TRUE AND is_postable = TRUE)),
    CONSTRAINT chk_accounts_control_contact CHECK (linked_contact_type IS NULL OR is_control_account = TRUE),
    UNIQUE (tenant_id, code)
);

CREATE INDEX IF NOT EXISTS idx_accounts_parent ON accounts(tenant_id, parent_code);
CREATE INDEX IF NOT EXISTS idx_accounts_type ON accounts(tenant_id, account_type);

-- Contacts (Customers / Suppliers / Employees)
CREATE TABLE IF NOT EXISTS contacts (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    contact_type VARCHAR(20) NOT NULL CHECK (contact_type IN ('customer', 'supplier', 'employee', 'other')),
    full_name VARCHAR(150) NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    tax_number VARCHAR(50),
    credit_limit DECIMAL(18, 4) DEFAULT 0,
    is_credit_hold BOOLEAN DEFAULT FALSE,
    notes TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    origin_device_id UUID,
    lamport_clock BIGINT DEFAULT 0,
    is_deleted BOOLEAN DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_contacts_type ON contacts(tenant_id, contact_type);
CREATE INDEX IF NOT EXISTS idx_contacts_phone ON contacts(tenant_id, phone);

-- Journal Entries (Aggregate Root - Immutable)
CREATE TABLE IF NOT EXISTS journal_entries (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    entry_number VARCHAR(50) NOT NULL,
    entry_date DATE NOT NULL,
    fiscal_period_id UUID,
    source_transaction_id UUID,
    template_code VARCHAR(50),
    memo_ar TEXT,
    is_closing_entry BOOLEAN DEFAULT FALSE,
    created_by_user_id UUID,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    posted_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    origin_device_id UUID,
    lamport_clock BIGINT DEFAULT 0,
    is_reversed BOOLEAN DEFAULT FALSE,
    reversal_entry_id UUID REFERENCES journal_entries(id),
    UNIQUE (tenant_id, entry_number)
);

CREATE INDEX IF NOT EXISTS idx_entries_date ON journal_entries(tenant_id, entry_date);
CREATE INDEX IF NOT EXISTS idx_entries_period ON journal_entries(tenant_id, fiscal_period_id);

-- Journal Lines
CREATE TABLE IF NOT EXISTS journal_lines (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    journal_entry_id UUID NOT NULL REFERENCES journal_entries(id) ON DELETE CASCADE,
    account_code VARCHAR(30) NOT NULL,
    side VARCHAR(6) NOT NULL CHECK (side IN ('debit', 'credit')),
    amount DECIMAL(18, 4) NOT NULL CHECK (amount > 0),
    currency_code VARCHAR(3) NOT NULL REFERENCES currencies(code),
    exchange_rate DECIMAL(18, 6) DEFAULT 1.0,
    base_amount DECIMAL(18, 4) NOT NULL CHECK (base_amount > 0),
    contact_id UUID REFERENCES contacts(id),
    open_item_id UUID,
    line_order SMALLINT NOT NULL,
    memo_ar TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_lines_entry ON journal_lines(journal_entry_id);
CREATE INDEX IF NOT EXISTS idx_lines_account ON journal_lines(tenant_id, account_code);
CREATE INDEX IF NOT EXISTS idx_lines_contact ON journal_lines(tenant_id, contact_id);

-- Sync Event Log (Core of Local-first replication)
CREATE TABLE IF NOT EXISTS event_log (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    entity_table VARCHAR(50) NOT NULL,
    entity_id UUID NOT NULL,
    action VARCHAR(10) NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    payload JSONB NOT NULL,
    origin_device_id UUID NOT NULL,
    lamport_clock BIGINT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_event_log_sync ON event_log(tenant_id, lamport_clock);

-- Audit Log (Strict audit trail)
CREATE TABLE IF NOT EXISTS audit_log (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    user_id UUID,
    device_id UUID,
    action_type VARCHAR(50) NOT NULL,
    resource_type VARCHAR(50) NOT NULL,
    resource_id UUID,
    metadata JSONB DEFAULT '{}',
    ip_address VARCHAR(45),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
