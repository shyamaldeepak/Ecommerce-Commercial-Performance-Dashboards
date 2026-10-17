{{ config(
    materialized = 'table'
) }}

WITH seller_performance AS (
    SELECT * FROM {{ ref('int_seller_performance_summary') }}
),

ranked AS (
    SELECT
        seller_id,
        seller_city,
        seller_state,
        total_items_sold,
        total_orders_fulfilled,
        total_merchandise_gmv,
        total_freight_collected,
        total_commercial_volume,
        avg_delivery_lead_days,
        delayed_orders_count,
        on_time_delivery_rate_pct,
        seller_avg_review_score,
        rated_transactions_count,
        seller_performance_tier,
        DENSE_RANK() OVER (ORDER BY total_merchandise_gmv DESC) AS national_seller_gmv_rank,
        DENSE_RANK() OVER (PARTITION BY seller_state ORDER BY total_merchandise_gmv DESC) AS state_seller_gmv_rank
    FROM seller_performance
)

SELECT * FROM ranked
