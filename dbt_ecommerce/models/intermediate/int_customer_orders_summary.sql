WITH customers AS (
    SELECT * FROM {{ ref('stg_customers') }}
),

orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
),

order_financials AS (
    SELECT
        order_id,
        order_total_merchandise_value,
        order_total_freight_value,
        order_total_items_value,
        items_in_order_count
    FROM (
        SELECT
            order_id,
            order_total_merchandise_value,
            order_total_freight_value,
            order_total_items_value,
            items_in_order_count,
            ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_item_id) AS rn
        FROM {{ ref('int_order_items_reconciled') }}
    )
    WHERE rn = 1
),

customer_orders AS (
    SELECT
        cust.customer_unique_id,
        cust.customer_city,
        cust.customer_state,
        ord.order_id,
        ord.order_status,
        ord.order_purchase_timestamp,
        ord.order_purchase_date,
        ord.order_year_month,
        ord.is_delivered,
        COALESCE(fin.order_total_merchandise_value, 0) AS order_merchandise_value,
        COALESCE(fin.order_total_freight_value, 0) AS order_freight_value,
        COALESCE(fin.order_total_items_value, 0) AS order_total_value,
        COALESCE(fin.items_in_order_count, 0) AS items_in_order_count
    FROM customers cust
    INNER JOIN orders ord
        ON cust.customer_id = ord.customer_id
    LEFT JOIN order_financials fin
        ON ord.order_id = fin.order_id
),

customer_aggregates AS (
    SELECT
        customer_unique_id,
        ANY_VALUE(customer_city) AS primary_city,
        ANY_VALUE(customer_state) AS primary_state,

        -- Cohort & Lifecycle Milestones
        MIN(order_purchase_timestamp) AS first_order_timestamp,
        MIN(order_purchase_date) AS first_order_date,
        STRFTIME(MIN(order_purchase_date), '%Y-%m') AS first_order_cohort_month,
        MAX(order_purchase_timestamp) AS last_order_timestamp,
        MAX(order_purchase_date) AS last_order_date,

        -- Order Volume & Monetary Values
        COUNT(DISTINCT order_id) AS lifetime_orders_count,
        SUM(is_delivered) AS lifetime_delivered_orders_count,
        SUM(items_in_order_count) AS lifetime_items_purchased_count,
        SUM(order_merchandise_value) AS lifetime_merchandise_spend,
        SUM(order_freight_value) AS lifetime_freight_spend,
        SUM(order_total_value) AS lifetime_total_spend,

        -- Derived Commercial KPIs
        ROUND(SUM(order_merchandise_value) / NULLIF(COUNT(DISTINCT order_id), 0), 2) AS customer_aov,
        CASE
            WHEN COUNT(DISTINCT order_id) > 1 THEN 1
            ELSE 0
        END AS is_repeat_customer,

        -- Recency Calculation (Days relative to snapshot anchor 2024-12-31)
        DATE_DIFF('day', MAX(order_purchase_date), CAST('2024-12-31' AS DATE)) AS recency_days

    FROM customer_orders
    GROUP BY customer_unique_id
),

segmented AS (
    SELECT
        *,
        CASE
            WHEN lifetime_orders_count >= 3 AND recency_days <= 120 THEN 'Champions'
            WHEN lifetime_orders_count >= 2 AND recency_days <= 180 THEN 'Loyal Customers'
            WHEN lifetime_orders_count = 1 AND recency_days <= 90 THEN 'New Customers'
            WHEN lifetime_orders_count >= 2 AND recency_days > 180 THEN 'At Risk Repeaters'
            WHEN recency_days > 365 THEN 'Hibernating'
            ELSE 'Potential Loyalists'
        END AS rfm_customer_segment
    FROM customer_aggregates
)

SELECT * FROM segmented
