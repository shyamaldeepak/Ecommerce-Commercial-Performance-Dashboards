WITH source AS (
    SELECT * FROM {{ source('raw_ecommerce', 'raw_order_payments') }}
),

transformed AS (
    SELECT
        TRIM(order_id) AS order_id,
        CAST(payment_sequential AS INTEGER) AS payment_sequential,
        LOWER(TRIM(payment_type)) AS payment_type,
        CAST(payment_installments AS INTEGER) AS payment_installments,
        CAST(payment_value AS DECIMAL(10, 2)) AS payment_value
    FROM source
)

SELECT * FROM transformed
