WITH sellers AS (
    SELECT * FROM {{ ref('stg_sellers') }}
),

order_items AS (
    SELECT * FROM {{ ref('int_order_items_reconciled') }}
),

reviews AS (
    SELECT
        order_id,
        AVG(review_score) AS order_avg_review_score,
        COUNT(review_id) AS order_review_count
    FROM {{ ref('stg_order_reviews') }}
    GROUP BY order_id
),

seller_item_level AS (
    SELECT
        items.seller_id,
        items.order_id,
        items.order_item_id,
        items.item_price,
        items.item_freight,
        items.item_total_value,
        items.is_delivered,
        items.delivery_lead_days,
        items.is_delayed_delivery,
        rev.order_avg_review_score
    FROM order_items items
    LEFT JOIN reviews rev
        ON items.order_id = rev.order_id
),

seller_aggregates AS (
    SELECT
        sel.seller_id,
        sel.seller_city,
        sel.seller_state,

        -- Commercial Volume
        COUNT(item.order_item_id) AS total_items_sold,
        COUNT(DISTINCT item.order_id) AS total_orders_fulfilled,
        ROUND(COALESCE(SUM(item.item_price), 0), 2) AS total_merchandise_gmv,
        ROUND(COALESCE(SUM(item.item_freight), 0), 2) AS total_freight_collected,
        ROUND(COALESCE(SUM(item.item_total_value), 0), 2) AS total_commercial_volume,

        -- Operational SLA Metrics
        ROUND(AVG(item.delivery_lead_days), 1) AS avg_delivery_lead_days,
        SUM(item.is_delayed_delivery) AS delayed_orders_count,
        ROUND(
            (1.0 - (CAST(SUM(item.is_delayed_delivery) AS FLOAT) / NULLIF(COUNT(item.order_item_id), 0))) * 100,
            2
        ) AS on_time_delivery_rate_pct,

        -- Customer Satisfaction Ratings
        ROUND(AVG(item.order_avg_review_score), 2) AS seller_avg_review_score,
        COUNT(item.order_avg_review_score) AS rated_transactions_count

    FROM sellers sel
    LEFT JOIN seller_item_level item
        ON sel.seller_id = item.seller_id
    GROUP BY
        sel.seller_id,
        sel.seller_city,
        sel.seller_state
),

tiered AS (
    SELECT
        *,
        CASE
            WHEN total_merchandise_gmv >= 20000 AND seller_avg_review_score >= 4.2 AND on_time_delivery_rate_pct >= 90.0 THEN 'Elite Merchant'
            WHEN total_merchandise_gmv >= 5000 AND seller_avg_review_score >= 3.8 THEN 'Established Merchant'
            WHEN total_merchandise_gmv < 1000 OR seller_avg_review_score < 3.2 OR on_time_delivery_rate_pct < 80.0 THEN 'Watchlist / At Risk'
            ELSE 'Standard Merchant'
        END AS seller_performance_tier
    FROM seller_aggregates
)

SELECT * FROM tiered
