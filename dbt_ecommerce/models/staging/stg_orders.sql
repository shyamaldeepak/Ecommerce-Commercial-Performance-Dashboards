WITH source AS (
    SELECT * FROM {{ source('raw_ecommerce', 'raw_orders') }}
),

transformed AS (
    SELECT
        TRIM(order_id) AS order_id,
        TRIM(customer_id) AS customer_id,
        LOWER(TRIM(order_status)) AS order_status,
        CAST(order_purchase_timestamp AS TIMESTAMP) AS order_purchase_timestamp,
        CAST(order_purchase_timestamp AS DATE) AS order_purchase_date,
        STRFTIME(CAST(order_purchase_timestamp AS DATE), '%Y-%m') AS order_year_month,
        CAST(order_approved_at AS TIMESTAMP) AS order_approved_at,
        CAST(order_delivered_carrier_date AS TIMESTAMP) AS order_delivered_carrier_date,
        CAST(order_delivered_customer_date AS TIMESTAMP) AS order_delivered_customer_date,
        CAST(order_estimated_delivery_date AS DATE) AS order_estimated_delivery_date,
        CASE
            WHEN LOWER(TRIM(order_status)) = 'delivered' THEN 1
            ELSE 0
        END AS is_delivered,
        CASE
            WHEN order_delivered_customer_date IS NOT NULL
            THEN DATE_DIFF('day', CAST(order_purchase_timestamp AS TIMESTAMP), CAST(order_delivered_customer_date AS TIMESTAMP))
            ELSE NULL
        END AS delivery_lead_days,
        CASE
            WHEN order_delivered_customer_date IS NOT NULL 
                 AND CAST(order_delivered_customer_date AS DATE) > CAST(order_estimated_delivery_date AS DATE)
            THEN 1
            ELSE 0
        END AS is_delayed_delivery
    FROM source
)

SELECT * FROM transformed
