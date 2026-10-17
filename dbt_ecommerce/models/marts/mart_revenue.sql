{{ config(
    materialized = 'table'
) }}

WITH reconciled_items AS (
    SELECT
        order_id,
        customer_id,
        order_status,
        order_purchase_timestamp,
        order_purchase_date,
        order_year_month,
        is_delivered,
        delivery_lead_days,
        is_delayed_delivery,
        items_in_order_count,
        order_total_merchandise_value,
        order_total_freight_value,
        order_total_items_value,
        order_total_payment,
        credit_card_payment,
        boleto_payment,
        voucher_payment,
        debit_card_payment,
        payment_splits_count,
        order_reconciliation_delta,
        is_reconciled_to_cent,
        ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_item_id) AS rn
    FROM {{ ref('int_order_items_reconciled') }}
),

distinct_orders AS (
    SELECT
        order_id,
        customer_id,
        order_status,
        order_purchase_timestamp,
        order_purchase_date,
        order_year_month,
        is_delivered,
        delivery_lead_days,
        is_delayed_delivery,
        items_in_order_count,

        -- Commercial Revenue Metrics
        order_total_merchandise_value AS gross_merchandise_value,
        order_total_freight_value AS freight_revenue,
        order_total_items_value AS total_commercial_order_value,

        -- Cash Collection Metrics
        order_total_payment AS total_payment_collected,
        credit_card_payment,
        boleto_payment,
        voucher_payment,
        debit_card_payment,
        payment_splits_count,

        -- Exact Cent-level Audit Columns
        order_reconciliation_delta,
        is_reconciled_to_cent,

        -- Primary Payment Category
        CASE
            WHEN credit_card_payment > 0 AND voucher_payment > 0 THEN 'Split (Card + Voucher)'
            WHEN credit_card_payment > 0 THEN 'Credit Card'
            WHEN boleto_payment > 0 THEN 'Boleto'
            WHEN voucher_payment > 0 THEN 'Voucher'
            WHEN debit_card_payment > 0 THEN 'Debit Card'
            ELSE 'Other'
        END AS primary_payment_method

    FROM reconciled_items
    WHERE rn = 1
)

SELECT * FROM distinct_orders
