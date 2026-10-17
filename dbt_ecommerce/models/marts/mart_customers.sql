{{ config(
    materialized = 'table'
) }}

WITH customer_summary AS (
    SELECT * FROM {{ ref('int_customer_orders_summary') }}
),

enriched AS (
    SELECT
        customer_unique_id,
        primary_city,
        primary_state,
        first_order_timestamp,
        first_order_date,
        first_order_cohort_month,
        last_order_timestamp,
        last_order_date,
        recency_days,
        lifetime_orders_count,
        lifetime_delivered_orders_count,
        lifetime_items_purchased_count,
        lifetime_merchandise_spend,
        lifetime_freight_spend,
        lifetime_total_spend,
        customer_aov,
        is_repeat_customer,
        rfm_customer_segment,
        ROUND(DATE_DIFF('day', first_order_date, last_order_date) / 30.4, 1) AS customer_tenure_months,
        CASE
            WHEN lifetime_total_spend >= 1000 THEN 'Tier 1 ($1,000+)'
            WHEN lifetime_total_spend >= 500 THEN 'Tier 2 ($500-$999)'
            WHEN lifetime_total_spend >= 200 THEN 'Tier 3 ($200-$499)'
            ELSE 'Tier 4 (<$200)'
        END AS spend_tier
    FROM customer_summary
)

SELECT * FROM enriched
