{{ config(
    materialized = 'table'
) }}

WITH products AS (
    SELECT * FROM {{ ref('stg_products') }}
),

order_items AS (
    SELECT * FROM {{ ref('stg_order_items') }}
),

orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
),

reviews AS (
    SELECT
        order_id,
        AVG(review_score) AS avg_order_review
    FROM {{ ref('stg_order_reviews') }}
    GROUP BY order_id
),

product_sales AS (
    SELECT
        item.product_id,
        COUNT(item.order_item_id) AS total_units_sold,
        COUNT(DISTINCT item.order_id) AS total_orders_count,
        ROUND(SUM(item.item_price), 2) AS total_merchandise_revenue,
        ROUND(SUM(item.item_freight), 2) AS total_freight_revenue,
        ROUND(SUM(item.item_total_value), 2) AS total_gross_value,
        ROUND(AVG(item.item_price), 2) AS avg_unit_selling_price,
        ROUND(AVG(item.item_freight), 2) AS avg_freight_per_unit,
        ROUND(AVG(rev.avg_order_review), 2) AS avg_review_score,
        COUNT(rev.avg_order_review) AS review_count
    FROM order_items item
    INNER JOIN orders ord
        ON item.order_id = ord.order_id
    LEFT JOIN reviews rev
        ON item.order_id = rev.order_id
    GROUP BY item.product_id
),

joined AS (
    SELECT
        p.product_id,
        p.product_category_name,
        p.product_photos_qty,
        p.product_weight_g,
        COALESCE(s.total_units_sold, 0) AS total_units_sold,
        COALESCE(s.total_orders_count, 0) AS total_orders_count,
        COALESCE(s.total_merchandise_revenue, 0) AS total_merchandise_revenue,
        COALESCE(s.total_freight_revenue, 0) AS total_freight_revenue,
        COALESCE(s.total_gross_value, 0) AS total_gross_value,
        COALESCE(s.avg_unit_selling_price, 0) AS avg_unit_selling_price,
        COALESCE(s.avg_freight_per_unit, 0) AS avg_freight_per_unit,
        s.avg_review_score,
        COALESCE(s.review_count, 0) AS review_count,
        DENSE_RANK() OVER (
            PARTITION BY p.product_category_name
            ORDER BY COALESCE(s.total_merchandise_revenue, 0) DESC
        ) AS rank_in_category
    FROM products p
    LEFT JOIN product_sales s
        ON p.product_id = s.product_id
)

SELECT * FROM joined
