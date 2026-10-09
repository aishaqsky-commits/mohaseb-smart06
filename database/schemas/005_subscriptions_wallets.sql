-- =========================================================================
-- Migration 005: Subscriptions & Yemeni Mobile Wallet Payment Module
-- Platform: Smart Merchant Accounting (Kuraimi, Jawwali, Jeeb, Floosak, OneCash)
-- =========================================================================

CREATE TABLE IF NOT EXISTS subscription_plans (
    id UUID PRIMARY KEY,
    code VARCHAR(30) UNIQUE NOT NULL,
    name_ar VARCHAR(100) NOT NULL,
    max_devices SMALLINT NOT NULL,
    monthly_price_yer DECIMAL(12, 2) NOT NULL,
    yearly_price_yer DECIMAL(12, 2) NOT NULL,
    monthly_ai_requests_quota INT DEFAULT 0,
    advanced_reports_allowed BOOLEAN DEFAULT FALSE,
    cloud_backup_allowed BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO subscription_plans (code, name_ar, max_devices, monthly_price_yer, yearly_price_yer, monthly_ai_requests_quota, advanced_reports_allowed, cloud_backup_allowed) VALUES
('free', 'الباقة المجانية', 1, 0, 0, 0, FALSE, FALSE),
('standard_2', 'باقة النمو (3 أجهزة)', 3, 15000, 150000, 200, TRUE, FALSE),
('pro_10', 'باقة برو الاحترافية (10 أجهزة)', 10, 35000, 350000, 1000, TRUE, TRUE)
ON CONFLICT (code) DO NOTHING;

CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL UNIQUE,
    plan_id UUID NOT NULL REFERENCES subscription_plans(id),
    status VARCHAR(20) DEFAULT 'trial' CHECK (status IN ('trial', 'active', 'grace_period', 'expired', 'suspended')),
    starts_at TIMESTAMPTZ NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    trial_ends_at TIMESTAMPTZ,
    ai_requests_used_this_cycle INT DEFAULT 0,
    cycle_reset_at TIMESTAMPTZ,
    auto_renew BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS subscription_events (
    id UUID PRIMARY KEY,
    subscription_id UUID NOT NULL REFERENCES subscriptions(id),
    event_type VARCHAR(50) NOT NULL,
    previous_plan_id UUID,
    new_plan_id UUID,
    event_metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS payment_providers (
    id UUID PRIMARY KEY,
    code VARCHAR(30) UNIQUE NOT NULL,
    name_ar VARCHAR(100) NOT NULL,
    integration_mode VARCHAR(10) NOT NULL CHECK (integration_mode IN ('push', 'pull', 'hybrid')),
    is_active BOOLEAN DEFAULT TRUE,
    webhook_secret VARCHAR(255),
    api_endpoint_url TEXT,
    config JSONB DEFAULT '{}'
);

INSERT INTO payment_providers (code, name_ar, integration_mode) VALUES
('kuraimi', 'بنك الكريمي (حسابك)', 'pull'),
('jawwali', 'جوالي (بنك اليمن والكويت)', 'hybrid'),
('jeeb', 'جيب (بنك التضامن)', 'hybrid'),
('floosak', 'فلوسك (بنك اليمن البحرين الشامل)', 'pull'),
('one_cash', 'ون كاش', 'push')
ON CONFLICT (code) DO NOTHING;

CREATE TABLE IF NOT EXISTS payment_transactions (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    subscription_id UUID NOT NULL REFERENCES subscriptions(id),
    plan_id UUID NOT NULL REFERENCES subscription_plans(id),
    provider_id UUID NOT NULL REFERENCES payment_providers(id),
    amount DECIMAL(18, 4) NOT NULL,
    currency_code VARCHAR(3) DEFAULT 'YER',
    reference_number VARCHAR(100),
    provider_transaction_id VARCHAR(100),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
    verified_at TIMESTAMPTZ,
    verified_by_user_id UUID,
    raw_response JSONB,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_payment_tx_status ON payment_transactions(tenant_id, status);

CREATE TABLE IF NOT EXISTS payment_webhook_logs (
    id UUID PRIMARY KEY,
    provider_code VARCHAR(30) NOT NULL,
    payload JSONB NOT NULL,
    headers JSONB,
    ip_address VARCHAR(45),
    is_processed BOOLEAN DEFAULT FALSE,
    processing_error TEXT,
    received_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ai_provider_configs (
    id UUID PRIMARY KEY,
    tenant_id UUID,
    provider_name VARCHAR(50) NOT NULL,
    model_name VARCHAR(100) NOT NULL,
    api_key_encrypted TEXT,
    is_custom_merchant_key BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ai_usage_log (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    user_id UUID,
    provider_name VARCHAR(50) NOT NULL,
    model_name VARCHAR(100) NOT NULL,
    tokens_in INT DEFAULT 0,
    tokens_out INT DEFAULT 0,
    cost_estimated_usd DECIMAL(10, 6) DEFAULT 0,
    action_type VARCHAR(50),
    success BOOLEAN DEFAULT TRUE,
    executed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
