-- =========================================================================
-- Migration 002: Inventory Management Module Schema
-- Platform: Smart Merchant Accounting (Perpetual & Periodic Inventory)
-- =========================================================================

CREATE TABLE IF NOT EXISTS warehouses (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    code VARCHAR(20) NOT NULL,
    name_ar VARCHAR(100) NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    origin_device_id UUID,
    lamport_clock BIGINT DEFAULT 0,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE (tenant_id, code)
);

CREATE TABLE IF NOT EXISTS item_categories (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    name_ar VARCHAR(100) NOT NULL,
    parent_category_id UUID REFERENCES item_categories(id),
    sort_order INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    is_deleted BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS units_of_measure (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    code VARCHAR(20) NOT NULL,
    name_ar VARCHAR(50) NOT NULL,
    symbol_ar VARCHAR(10) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE (tenant_id, code)
);

CREATE TABLE IF NOT EXISTS items (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    sku VARCHAR(50),
    name_ar VARCHAR(200) NOT NULL,
    category_id UUID REFERENCES item_categories(id),
    primary_uom_id UUID REFERENCES units_of_measure(id),
    item_type VARCHAR(20) DEFAULT 'stock' CHECK (item_type IN ('stock', 'service', 'composite')),
    has_expiry_date BOOLEAN DEFAULT FALSE,
    min_stock_alert DECIMAL(14, 4) DEFAULT 0,
    default_sale_price DECIMAL(18, 4) DEFAULT 0,
    current_avg_cost DECIMAL(18, 4) DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    origin_device_id UUID,
    lamport_clock BIGINT DEFAULT 0,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE (tenant_id, sku)
);

CREATE TABLE IF NOT EXISTS item_barcodes (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    item_id UUID NOT NULL REFERENCES items(id) ON DELETE CASCADE,
    barcode VARCHAR(100) NOT NULL,
    uom_id UUID REFERENCES units_of_measure(id),
    UNIQUE (tenant_id, barcode)
);

CREATE TABLE IF NOT EXISTS item_batches (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    item_id UUID NOT NULL REFERENCES items(id),
    batch_number VARCHAR(100) NOT NULL,
    expiry_date DATE,
    unit_cost DECIMAL(18, 4) NOT NULL,
    quantity_received DECIMAL(14, 4) NOT NULL,
    quantity_remaining DECIMAL(14, 4) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tenant_id, item_id, batch_number)
);

CREATE INDEX IF NOT EXISTS idx_batches_fefo ON item_batches(tenant_id, item_id, expiry_date, quantity_remaining);

-- Stock Movements (Append-only Ledger)
CREATE TABLE IF NOT EXISTS stock_movements (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    warehouse_id UUID NOT NULL REFERENCES warehouses(id),
    item_id UUID NOT NULL REFERENCES items(id),
    batch_id UUID REFERENCES item_batches(id),
    movement_type VARCHAR(30) NOT NULL CHECK (
        movement_type IN ('purchase_in', 'sale_out', 'return_in', 'return_out',
                         'transfer_in', 'transfer_out', 'damage_out', 'opening_balance',
                         'inventory_count_adj_in', 'inventory_count_adj_out')
    ),
    quantity DECIMAL(14, 4) NOT NULL,
    unit_cost DECIMAL(18, 4) NOT NULL,
    total_cost DECIMAL(18, 4) NOT NULL,
    movement_date DATE NOT NULL,
    journal_entry_id UUID,
    source_reference VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    origin_device_id UUID,
    lamport_clock BIGINT DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_stock_movements_item ON stock_movements(tenant_id, item_id, movement_date);

-- Materialized Stock Balances (Performance Aggregate)
CREATE TABLE IF NOT EXISTS stock_balances (
    tenant_id UUID NOT NULL,
    warehouse_id UUID NOT NULL REFERENCES warehouses(id),
    item_id UUID NOT NULL REFERENCES items(id),
    current_quantity DECIMAL(14, 4) NOT NULL DEFAULT 0,
    reserved_quantity DECIMAL(14, 4) NOT NULL DEFAULT 0,
    total_cost_value DECIMAL(18, 4) NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (tenant_id, warehouse_id, item_id)
);

-- Stock Count Sessions
CREATE TABLE IF NOT EXISTS stock_count_sessions (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    warehouse_id UUID NOT NULL REFERENCES warehouses(id),
    session_number VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'approved', 'cancelled')),
    started_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    approved_at TIMESTAMPTZ,
    approved_by_user_id UUID,
    journal_entry_id UUID
);

CREATE TABLE IF NOT EXISTS stock_count_lines (
    id UUID PRIMARY KEY,
    session_id UUID NOT NULL REFERENCES stock_count_sessions(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES items(id),
    system_quantity DECIMAL(14, 4) NOT NULL,
    counted_quantity DECIMAL(14, 4) NOT NULL,
    unit_cost DECIMAL(18, 4) NOT NULL,
    difference_quantity DECIMAL(14, 4) GENERATED ALWAYS AS (counted_quantity - system_quantity) STORED,
    difference_value DECIMAL(18, 4) GENERATED ALWAYS AS ((counted_quantity - system_quantity) * unit_cost) STORED
);
