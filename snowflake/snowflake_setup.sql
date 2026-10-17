-- =============================================================================
-- Snowflake Data Warehouse Setup & DDL Scripts
-- Ecommerce Commercial Performance Marts
-- =============================================================================

-- 1. Create Virtual Warehouse, Database, and Schemas
CREATE WAREHOUSE IF NOT EXISTS COMMERCIAL_ANALYTICS_WH
    WITH WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 180
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

CREATE DATABASE IF NOT EXISTS ECOMMERCE_DW;

CREATE SCHEMA IF NOT EXISTS ECOMMERCE_DW.RAW;
CREATE SCHEMA IF NOT EXISTS ECOMMERCE_DW.STAGING;
CREATE SCHEMA IF NOT EXISTS ECOMMERCE_DW.INTERMEDIATE;
CREATE SCHEMA IF NOT EXISTS ECOMMERCE_DW.MARTS;

USE WAREHOUSE COMMERCIAL_ANALYTICS_WH;
USE DATABASE ECOMMERCE_DW;

-- 2. Raw Tables DDL
USE SCHEMA RAW;

CREATE OR REPLACE TABLE raw_customers (
    customer_id VARCHAR(64) PRIMARY KEY,
    customer_unique_id VARCHAR(64),
    customer_zip_code VARCHAR(16),
    customer_city VARCHAR(64),
    customer_state VARCHAR(8),
    created_at TIMESTAMP_NTZ
);

CREATE OR REPLACE TABLE raw_orders (
    order_id VARCHAR(64) PRIMARY KEY,
    customer_id VARCHAR(64),
    order_status VARCHAR(32),
    order_purchase_timestamp TIMESTAMP_NTZ,
    order_approved_at TIMESTAMP_NTZ,
    order_delivered_carrier_date TIMESTAMP_NTZ,
    order_delivered_customer_date TIMESTAMP_NTZ,
    order_estimated_delivery_date DATE
);

CREATE OR REPLACE TABLE raw_order_items (
    order_id VARCHAR(64),
    order_item_id INT,
    product_id VARCHAR(64),
    seller_id VARCHAR(64),
    shipping_limit_date TIMESTAMP_NTZ,
    price NUMBER(10, 2),
    freight_value NUMBER(10, 2)
);

CREATE OR REPLACE TABLE raw_order_payments (
    order_id VARCHAR(64),
    payment_sequential INT,
    payment_type VARCHAR(32),
    payment_installments INT,
    payment_value NUMBER(10, 2)
);

CREATE OR REPLACE TABLE raw_order_reviews (
    review_id VARCHAR(64) PRIMARY KEY,
    order_id VARCHAR(64),
    review_score INT,
    review_comment_title VARCHAR(256),
    review_creation_date DATE,
    review_answer_timestamp TIMESTAMP_NTZ
);

CREATE OR REPLACE TABLE raw_products (
    product_id VARCHAR(64) PRIMARY KEY,
    product_category_name VARCHAR(128),
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

CREATE OR REPLACE TABLE raw_sellers (
    seller_id VARCHAR(64) PRIMARY KEY,
    seller_zip_code_prefix VARCHAR(16),
    seller_city VARCHAR(64),
    seller_state VARCHAR(8)
);

CREATE OR REPLACE TABLE raw_promotions (
    promo_id VARCHAR(64) PRIMARY KEY,
    promo_code VARCHAR(64),
    discount_pct NUMBER(5, 2),
    channel VARCHAR(64),
    valid_from DATE,
    valid_to DATE,
    is_active BOOLEAN
);

-- 3. Mart 1: mart_revenue DDL
USE SCHEMA MARTS;

CREATE OR REPLACE TABLE mart_revenue (
    order_id VARCHAR(64) PRIMARY KEY,
    customer_id VARCHAR(64),
    order_status VARCHAR(32),
    order_purchase_timestamp TIMESTAMP_NTZ,
    order_purchase_date DATE,
    order_year_month VARCHAR(7),
    is_delivered INT,
    delivery_lead_days INT,
    is_delayed_delivery INT,
    items_in_order_count INT,
    gross_merchandise_value NUMBER(10, 2),
    freight_revenue NUMBER(10, 2),
    total_commercial_order_value NUMBER(10, 2),
    total_payment_collected NUMBER(10, 2),
    credit_card_payment NUMBER(10, 2),
    boleto_payment NUMBER(10, 2),
    voucher_payment NUMBER(10, 2),
    debit_card_payment NUMBER(10, 2),
    payment_splits_count INT,
    order_reconciliation_delta NUMBER(10, 2),
    is_reconciled_to_cent INT,
    primary_payment_method VARCHAR(32)
);

-- 4. Mart 2: mart_customers DDL
CREATE OR REPLACE TABLE mart_customers (
    customer_unique_id VARCHAR(64) PRIMARY KEY,
    primary_city VARCHAR(64),
    primary_state VARCHAR(8),
    first_order_timestamp TIMESTAMP_NTZ,
    first_order_date DATE,
    first_order_cohort_month VARCHAR(7),
    last_order_timestamp TIMESTAMP_NTZ,
    last_order_date DATE,
    recency_days INT,
    lifetime_orders_count INT,
    lifetime_delivered_orders_count INT,
    lifetime_items_purchased_count INT,
    lifetime_merchandise_spend NUMBER(12, 2),
    lifetime_freight_spend NUMBER(12, 2),
    lifetime_total_spend NUMBER(12, 2),
    customer_aov NUMBER(10, 2),
    is_repeat_customer INT,
    rfm_customer_segment VARCHAR(64),
    customer_tenure_months NUMBER(10, 1),
    spend_tier VARCHAR(32)
);

-- 5. Mart 3: mart_products DDL
CREATE OR REPLACE TABLE mart_products (
    product_id VARCHAR(64) PRIMARY KEY,
    product_category_name VARCHAR(128),
    product_photos_qty INT,
    product_weight_g INT,
    total_units_sold INT,
    total_orders_count INT,
    total_merchandise_revenue NUMBER(12, 2),
    total_freight_revenue NUMBER(12, 2),
    total_gross_value NUMBER(12, 2),
    avg_unit_selling_price NUMBER(10, 2),
    avg_freight_per_unit NUMBER(10, 2),
    avg_review_score NUMBER(3, 2),
    review_count INT,
    rank_in_category INT
);

-- 6. Mart 4: mart_sellers DDL
CREATE OR REPLACE TABLE mart_sellers (
    seller_id VARCHAR(64) PRIMARY KEY,
    seller_city VARCHAR(64),
    seller_state VARCHAR(8),
    total_items_sold INT,
    total_orders_fulfilled INT,
    total_merchandise_gmv NUMBER(12, 2),
    total_freight_collected NUMBER(12, 2),
    total_commercial_volume NUMBER(12, 2),
    avg_delivery_lead_days NUMBER(5, 1),
    delayed_orders_count INT,
    on_time_delivery_rate_pct NUMBER(5, 2),
    seller_avg_review_score NUMBER(3, 2),
    rated_transactions_count INT,
    seller_performance_tier VARCHAR(64),
    national_seller_gmv_rank INT,
    state_seller_gmv_rank INT
);
