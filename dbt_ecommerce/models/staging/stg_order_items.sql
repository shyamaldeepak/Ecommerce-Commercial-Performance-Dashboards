WITH source AS (
    SELECT * FROM {{ source('raw_ecommerce', 'raw_order_items') }}
),

transformed AS (
    SELECT
        TRIM(order_id) AS order_id,
        CAST(order_item_id AS INTEGER) AS order_item_id,
        TRIM(product_id) AS product_id,
        TRIM(seller_id) AS seller_id,
        CAST(shipping_limit_date AS TIMESTAMP) AS shipping_limit_date,
        CAST(price AS DECIMAL(10, 2)) AS item_price,
        CAST(freight_value AS DECIMAL(10, 2)) AS item_freight,
        CAST(price + freight_value AS DECIMAL(10, 2)) AS item_total_value
    FROM source
)

SELECT * FROM transformed
