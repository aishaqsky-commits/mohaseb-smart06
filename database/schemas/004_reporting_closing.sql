-- =========================================================================
-- Migration 004: Financial Reporting & Period Closing Schema
-- Platform: Smart Merchant Accounting (Hot/Cold Period Architecture)
-- =========================================================================

CREATE TABLE IF NOT EXISTS fiscal_periods (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    period_name VARCHAR(50) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_closed BOOLEAN DEFAULT FALSE,
    closed_at TIMESTAMPTZ,
    closed_by_user_id UUID,
    closing_journal_entry_id UUID,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tenant_id, start_date, end_date)
);

CREATE TABLE IF NOT EXISTS account_period_balances (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    fiscal_period_id UUID NOT NULL REFERENCES fiscal_periods(id),
    account_code VARCHAR(30) NOT NULL,
    opening_debit DECIMAL(18, 4) DEFAULT 0,
    opening_credit DECIMAL(18, 4) DEFAULT 0,
    period_debit DECIMAL(18, 4) DEFAULT 0,
    period_credit DECIMAL(18, 4) DEFAULT 0,
    closing_debit DECIMAL(18, 4) DEFAULT 0,
    closing_credit DECIMAL(18, 4) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tenant_id, fiscal_period_id, account_code)
);

CREATE TABLE IF NOT EXISTS account_running_balances (
    tenant_id UUID NOT NULL,
    account_code VARCHAR(30) NOT NULL,
    current_debit DECIMAL(18, 4) DEFAULT 0,
    current_credit DECIMAL(18, 4) DEFAULT 0,
    net_balance DECIMAL(18, 4) DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (tenant_id, account_code)
);

CREATE TABLE IF NOT EXISTS daily_closures (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    closure_date DATE NOT NULL,
    expected_cash DECIMAL(18, 4) NOT NULL,
    actual_cash DECIMAL(18, 4) NOT NULL,
    difference_amount DECIMAL(18, 4) GENERATED ALWAYS AS (actual_cash - expected_cash) STORED,
    status VARCHAR(20) DEFAULT 'closed' CHECK (status IN ('closed', 'reopened')),
    notes TEXT,
    closed_by_user_id UUID,
    closed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    reopened_at TIMESTAMPTZ,
    UNIQUE (tenant_id, closure_date)
);

CREATE TABLE IF NOT EXISTS daily_business_results (
    tenant_id UUID NOT NULL,
    result_date DATE NOT NULL,
    total_sales DECIMAL(18, 4) DEFAULT 0,
    total_cogs DECIMAL(18, 4) DEFAULT 0,
    gross_profit DECIMAL(18, 4) DEFAULT 0,
    daily_expenses DECIMAL(18, 4) DEFAULT 0,
    daily_amortized_expenses DECIMAL(18, 4) DEFAULT 0,
    net_profit DECIMAL(18, 4) DEFAULT 0,
    cash_collected DECIMAL(18, 4) DEFAULT 0,
    credit_sales DECIMAL(18, 4) DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (tenant_id, result_date)
);

CREATE TABLE IF NOT EXISTS report_definitions (
    code VARCHAR(50) PRIMARY KEY,
    name_ar VARCHAR(100) NOT NULL,
    category VARCHAR(30) NOT NULL,
    calculation_logic VARCHAR(50) NOT NULL,
    parameters_schema JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS report_execution_log (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    user_id UUID,
    report_code VARCHAR(50) REFERENCES report_definitions(code),
    parameters JSONB,
    execution_duration_ms INT,
    executed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
